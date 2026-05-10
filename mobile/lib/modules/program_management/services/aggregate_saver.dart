import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/program_management.dart';

class AggregateSaver {
  const AggregateSaver(this._programRepository);

  final ProgramRepository _programRepository;

  Future<Program> save(ProgramDraft draft) async {
    final aggregate = draft.toAggregate();
    return _programRepository.saveProgramAggregate(aggregate);
  }
}
