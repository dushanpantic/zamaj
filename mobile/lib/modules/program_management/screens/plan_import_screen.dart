import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_event.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_state.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/plan_parse_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/plan_text_input.dart';

const String _examplePlan =
    'Upper Body\n'
    '\n'
    'Day 1\n'
    'Bench Press\n'
    '4x8 100kg 2m\n'
    '\n'
    'Superset:\n'
    'Rows\n'
    '4x8 80kg\n'
    'Pull-ups\n'
    '3x10\n';

class PlanImportScreen extends StatefulWidget {
  const PlanImportScreen({super.key});

  @override
  State<PlanImportScreen> createState() => _PlanImportScreenState();
}

class _PlanImportScreenState extends State<PlanImportScreen> {
  late final TextEditingController _controller;
  bool _exampleExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialText = context.read<PlanImportBloc>().state.text;
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    context.read<PlanImportBloc>().add(PlanImportTextChanged(text: text));
  }

  void _onParseRequested() {
    context.read<PlanImportBloc>().add(const PlanImportParseRequested());
  }

  Future<void> _onPastePressed() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _onTextChanged(text);
  }

  void _useExample() {
    _controller.text = _examplePlan;
    _controller.selection = const TextSelection.collapsed(
      offset: _examplePlan.length,
    );
    _onTextChanged(_examplePlan);
    setState(() => _exampleExpanded = false);
  }

  Future<void> _navigateToPreview({required PlanImportSuccess state}) async {
    await Navigator.pushNamed(
      context,
      ProgramManagementRoutes.planPreview,
      arguments: PlanPreviewArgs(draft: state.draft, warnings: state.warnings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocListener<PlanImportBloc, PlanImportState>(
      listener: (context, state) {
        if (state is PlanImportSuccess) {
          _navigateToPreview(state: state);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: const Text('Import from text')),
        body: BlocBuilder<PlanImportBloc, PlanImportState>(
          builder: (context, state) {
            final isParsing = state is PlanImportParsing;
            final canParse = state.text.isNotEmpty && !isParsing;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InputToolbar(
                    onPastePressed: isParsing ? null : _onPastePressed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PlanTextInput(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    enabled: !isParsing,
                  ),
                  if (state is PlanImportFailure) ...[
                    const SizedBox(height: AppSpacing.md),
                    PlanParseErrorBanner(error: state.error),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _ExampleDisclosure(
                    expanded: _exampleExpanded,
                    onToggle: () =>
                        setState(() => _exampleExpanded = !_exampleExpanded),
                    onUseExample: isParsing ? null : _useExample,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isParsing)
                    Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    )
                  else
                    FilledButton(
                      onPressed: canParse ? _onParseRequested : null,
                      child: const Text('Parse'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputToolbar extends StatelessWidget {
  const _InputToolbar({required this.onPastePressed});

  final VoidCallback? onPastePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Paste or type your plan',
            style: typography.label.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        TextButton.icon(
          onPressed: onPastePressed,
          icon: const Icon(Icons.content_paste, size: 18),
          label: const Text('Paste'),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: const Size(0, AppSpacing.touchMin),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}

class _ExampleDisclosure extends StatelessWidget {
  const _ExampleDisclosure({
    required this.expanded,
    required this.onToggle,
    required this.onUseExample,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onUseExample;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: colors.onSurfaceMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'See example format',
                      style: typography.label.copyWith(color: colors.onSurface),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _examplePlan,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onUseExample,
                  icon: const Icon(Icons.south, size: 18),
                  label: const Text('Use this example'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    minimumSize: const Size(0, AppSpacing.touchMin),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
