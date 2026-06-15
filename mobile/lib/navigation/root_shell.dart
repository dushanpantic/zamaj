import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/bloc/exercise_library_list/bloc.dart';
import 'package:zamaj/modules/exercise_library/screens/exercise_library_list_screen.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_bloc.dart';
import 'package:zamaj/modules/program_management/screens/program_list_screen.dart';

/// Top-level app shell hosting the two primary destinations — Programs and
/// Library — behind a Material [NavigationBar].
///
/// Both tab roots live in an [IndexedStack] so each keeps its state (scroll,
/// search, filters) across tab switches, and both blocs are created up front.
/// Detail screens push **over** this shell through the root [Navigator], so the
/// bar is absent in-session and on every pushed surface.
///
/// System back from either tab exits the app: the shell is a single route with
/// no extra back stack, so no [PopScope] interception is added. Return-to-first
/// -tab is deferred until a Home tab exists to serve as the unwind target.
///
/// The bar is a standard full-width Material 3 [NavigationBar]; Liquid Glass /
/// floating-capsule styling is intentionally out of scope and would be a
/// contained swap of this widget's `bottomNavigationBar` with no IA change.
class RootShellScreen extends StatefulWidget {
  const RootShellScreen({super.key});

  @override
  State<RootShellScreen> createState() => _RootShellScreenState();
}

class _RootShellScreenState extends State<RootShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [_programsTab(context), _libraryTab(context)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _programsTab(BuildContext context) => BlocProvider(
    create: (_) =>
        ProgramListBloc(programRepository: context.read<ProgramRepository>()),
    child: const ProgramListScreen(),
  );

  Widget _libraryTab(BuildContext context) => BlocProvider(
    create: (_) => ExerciseLibraryListBloc(
      exerciseLibraryRepository: context.read<ExerciseLibraryRepository>(),
    ),
    child: const ExerciseLibraryListScreen(),
  );
}
