import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/ModelProvider.dart';

/// Provides job CRUD and state machine enforcement.
/// FR-68 verification requires access to quotes, so [verifyAcceptedQuote]
/// must be supplied by the caller (typically QuoteService) to avoid a
/// circular dependency.
class JobService {
  // ── Valid state transitions (Phase 1) ───────────────────────────────────
  static const _validTransitions = <JobStatus, List<JobStatus>>{
    JobStatus.Enquiry: [JobStatus.Quoted],
    JobStatus.Quoted: [JobStatus.Contracted],
    JobStatus.Contracted: [],
  };

  /// Creates a new job with status [Enquiry].
  /// Enforces FR-06: contractValue >= 0.
  static Future<Job> createJob({
    required String jobName,
    required String client,
    String? location,
    String? description,
    double contractValue = 0,
  }) async {
    if (contractValue < 0) {
      throw ArgumentError('Contract value must be >= 0 (FR-06)');
    }

    final job = Job(
      jobName: jobName,
      client: client,
      location: location,
      description: description,
      status: JobStatus.Enquiry,
      contractValue: contractValue,
    );

    final request = ModelMutations.create(job);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to create job: ${response.errors}');
    }
    return response.data!;
  }

  /// Lists all jobs, optionally filtered by [status].
  static Future<List<Job>> listJobs({JobStatus? status}) async {
    final request = status != null
        ? ModelQueries.list(Job.classType, where: Job.STATUS.eq(status))
        : ModelQueries.list(Job.classType);

    final response = await Amplify.API.query(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to list jobs: ${response.errors}');
    }
    return response.data?.items.whereType<Job>().toList() ?? [];
  }

  /// Fetches a single job by ID.
  static Future<Job?> getJob(String jobId) async {
    final request = ModelQueries.get(
      Job.classType,
      JobModelIdentifier(id: jobId),
    );
    final response = await Amplify.API.query(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to get job: ${response.errors}');
    }
    return response.data;
  }

  /// Transitions the job to [newStatus], enforcing the state machine (FR-05).
  ///
  /// For Quoted → Contracted (FR-68): the caller MUST set
  /// [hasAcceptedQuote] to true, confirming that an accepted quote exists.
  /// This avoids a circular dependency between JobService and QuoteService
  /// while still enforcing the business rule at the gate.
  static Future<Job> updateJobStatus(
    Job job,
    JobStatus newStatus, {
    double? contractValue,
    bool hasAcceptedQuote = false,
  }) async {
    final allowed = _validTransitions[job.status] ?? [];
    if (!allowed.contains(newStatus)) {
      throw StateError(
        'Invalid transition: ${job.status.name} → ${newStatus.name} (FR-05)',
      );
    }

    // FR-68: job cannot move to Contracted without an accepted quote
    if (newStatus == JobStatus.Contracted && !hasAcceptedQuote) {
      throw StateError(
        'Cannot transition to Contracted without an accepted quote (FR-68)',
      );
    }

    var updated = job.copyWith(status: newStatus);

    if (contractValue != null) {
      if (contractValue < 0) {
        throw ArgumentError('Contract value must be >= 0 (FR-06)');
      }
      updated = updated.copyWith(contractValue: contractValue);
    }

    final request = ModelMutations.update(updated);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to update job status: ${response.errors}');
    }
    return response.data!;
  }
}
