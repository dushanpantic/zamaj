import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_event.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_state.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/plan_parse_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/plan_text_input.dart';

class PlanImportScreen extends StatefulWidget {
  const PlanImportScreen({super.key});

  @override
  State<PlanImportScreen> createState() => _PlanImportScreenState();
}

class _PlanImportScreenState extends State<PlanImportScreen> {
  late final TextEditingController _controller;

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
        appBar: AppBar(
          title: const Text('Import from text'),
          backgroundColor: colors.background,
          foregroundColor: colors.onBackground,
          elevation: 0,
        ),
        body: BlocBuilder<PlanImportBloc, PlanImportState>(
          builder: (context, state) {
            final isParsing = state is PlanImportParsing;
            final canParse = state.text.isNotEmpty && !isParsing;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlanTextInput(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    enabled: !isParsing,
                  ),
                  if (state is PlanImportFailure) ...[
                    const SizedBox(height: AppSpacing.md),
                    PlanParseErrorBanner(error: state.error),
                  ],
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
