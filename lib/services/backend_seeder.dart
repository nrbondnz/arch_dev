import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Seeds the backend with the canonical ARCH test dataset via real API calls.
///
/// Requires an authenticated admin-manager session.
/// Each [seed] call logs progress via the [onLog] callback so the UI can
/// show a live activity feed.
///
/// Data story:
///   J001 — 14 Hillcrest Rd | InProgress  | 3 stages, 2 WPs, 2 variations, 1 paid claim
///   J002 — 8 Marine Parade  | Quoted      | quote with 2 line items, DocumentSent
///   J003 — 3 Tui Street     | Enquiry     | bare job only
class BackendSeeder {
  BackendSeeder({required this.onLog});

  final void Function(String message, {bool isError}) onLog;

  // ── Public entry point ───────────────────────────────────────────────────────

  Future<void> seed() async {
    onLog('Starting ARCH test data seed…');
    try {
      await _clearAll();
      final j001Id = await _seedJ001();
      await _seedJ002();
      await _seedJ003();
      onLog('');
      onLog('All done. J001=$j001Id');
    } on Exception catch (e) {
      onLog('Seed failed: $e', isError: true);
      rethrow;
    }
  }

  // ── J001 — 14 Hillcrest Rd (InProgress) ─────────────────────────────────────

  Future<String> _seedJ001() async {
    onLog('── J001 ──────────────────────────────────────');

    // 1. Create job
    onLog('  → createJob (14 Hillcrest Rd)');
    final job = await _callJob({
      'apiFunction': 'createJob',
      'clientName': 'Apex Construction',
      'clientContactName': 'Sarah Nguyen',
      'clientEmail': 'sarah@apexconstruction.co.nz',
      'clientPhone': '021 555 0101',
      'siteAddress': '14 Hillcrest Rd, Auckland',
      'description': 'Brick and blockwork — residential new build',
      'contractType': 'LumpSum',
      'paymentTerms': '20th of following month',
    });
    final j001 = job['id'] as String;
    onLog('  ✓ Job created: $j001');

    // 2. Advance to InProgress
    onLog('  → updateJob → InProgress');
    await _callJob({'apiFunction': 'updateJob', 'jobId': j001, 'status': 'InProgress'});
    onLog('  ✓ Status: InProgress');

    // 3. Stage 1 — Foundation blockwork (Paid)
    onLog('  → createStage: Foundation blockwork (\$18,500 | Milestone | Paid)');
    final s1 = await _createStage({
      'jobId': j001,
      'sequence': 1,
      'description': 'Foundation blockwork',
      'scheduledValue': 18500.0,
      'triggerType': 'Milestone',
      'triggerValue': 'Foundations completed and inspected',
      'retentionRate': 0.05,
      'status': 'Paid',
      'percentComplete': 100.0,
    });
    onLog('  ✓ Stage 1: ${s1['id']}');

    // 4. Stage 2 — External brickwork (Active)
    onLog('  → createStage: External brickwork (\$42,000 | 80% | Active)');
    final s2 = await _createStage({
      'jobId': j001,
      'sequence': 2,
      'description': 'External brickwork',
      'scheduledValue': 42000.0,
      'triggerType': 'PercentComplete',
      'triggerValue': '80',
      'retentionRate': 0.05,
      'status': 'Active',
      'percentComplete': 62.0,
    });
    onLog('  ✓ Stage 2: ${s2['id']}');

    // 5. Stage 3 — Retaining walls (Pending)
    onLog('  → createStage: Retaining walls (\$12,000 | Manual | Pending)');
    final s3 = await _createStage({
      'jobId': j001,
      'sequence': 3,
      'description': 'Retaining walls',
      'scheduledValue': 12000.0,
      'triggerType': 'Manual',
      'retentionRate': 0.05,
      'status': 'Pending',
    });
    onLog('  ✓ Stage 3: ${s3['id']}');

    // 6. Work Package 1 — Foundation (Completed)
    onLog('  → createWorkPackage: Foundation (Tom Chen | Completed)');
    final wp1 = await _createWorkPackage({
      'jobId': j001,
      'description': 'Foundation blockwork',
      'siteManagerId': 'sm-tom-chen',
      'plannedStart': '2025-01-06',
      'plannedEnd': '2025-02-14',
      'relatedStageIds': [s1['id'] as String],
      'status': 'Completed',
    });
    onLog('  ✓ WP1: ${wp1['id']}');

    // 7. Work Package 2 — External brickwork (VariationPending)
    onLog('  → createWorkPackage: External brickwork (Tom Chen | VariationPending)');
    final wp2 = await _createWorkPackage({
      'jobId': j001,
      'description': 'External brickwork',
      'siteManagerId': 'sm-tom-chen',
      'plannedStart': '2025-02-17',
      'plannedEnd': '2025-05-02',
      'relatedStageIds': [s2['id'] as String],
      'status': 'VariationPending',
    });
    onLog('  ✓ WP2: ${wp2['id']}');

    // 8. Variation V001 — Extra brick pier (Approved)
    onLog('  → createVariation: brick pier \$450');
    final v1 = await _callVariation({
      'apiFunction': 'createVariation',
      'jobId': j001,
      'workPackageId': wp1['id'],
      'description': 'Additional brick pier at north-east corner',
      'reason': 'Engineer instruction',
      'clientInitiated': false,
      'price': 450.0,
      'timeImpactDays': 0,
    });
    final v1Id = v1['id'] as String;
    onLog('  ✓ V001 created: $v1Id');
    onLog('  → V001: sendDocument');
    await _callVariation({'apiFunction': 'sendDocument', 'variationId': v1Id});
    onLog('  → V001: recordApproved');
    await _callVariation({
      'apiFunction': 'recordApproved',
      'variationId': v1Id,
      'approvedAt': '2025-02-20',
    });
    onLog('  ✓ V001: Approved');

    // 9. Variation V002 — Window reveal change (DocumentSent)
    onLog('  → createVariation: window reveals \$1,200');
    final v2 = await _callVariation({
      'apiFunction': 'createVariation',
      'jobId': j001,
      'workPackageId': wp2['id'],
      'description': 'Window reveal brickwork change — wider reveals',
      'reason': 'Client request',
      'clientInitiated': true,
      'clientContactName': 'Sarah Nguyen',
      'price': 1200.0,
      'timeImpactDays': 1,
    });
    final v2Id = v2['id'] as String;
    onLog('  ✓ V002 created: $v2Id');
    onLog('  → V002: sendDocument');
    await _callVariation({'apiFunction': 'sendDocument', 'variationId': v2Id});
    onLog('  ✓ V002: DocumentSent');

    // 10. Claim for Stage 1 (Paid)
    onLog('  → createClaim: Stage 1 (April 2025)');
    final claim = await _callClaim({
      'apiFunction': 'createClaim',
      'stageId': s1['id'],
      'jobId': j001,
      'periodDescription': 'April 2025 — foundation complete',
      'variationsIncluded': [v1Id],
    });
    final claimId = claim['id'] as String;
    onLog('  ✓ Claim created: $claimId (total: \$${claim['claimTotal']})');
    onLog('  → Claim: sendDocument');
    await _callClaim({'apiFunction': 'sendDocument', 'claimId': claimId});
    onLog('  → Claim: recordPaid');
    await _callClaim({
      'apiFunction': 'recordPaid',
      'claimId': claimId,
      'paidAmount': claim['claimTotal'],
      'paidAt': '2025-04-09',
      'notes': 'Paid in full — April run',
    });
    onLog('  ✓ Claim: Paid');

    return j001;
  }

  // ── J002 — 8 Marine Parade (Quoted) ─────────────────────────────────────────

  Future<void> _seedJ002() async {
    onLog('── J002 ──────────────────────────────────────');

    onLog('  → createJob (8 Marine Parade)');
    final job = await _callJob({
      'apiFunction': 'createJob',
      'clientName': 'Beachfront Homes Ltd',
      'clientContactName': 'Mark Thompson',
      'clientEmail': 'mark@beachfronthomes.co.nz',
      'siteAddress': '8 Marine Parade, Tauranga',
      'description': 'Feature stone cladding — coastal residential',
      'contractType': 'LumpSum',
    });
    final j002 = job['id'] as String;
    onLog('  ✓ Job created: $j002');
    onLog('  → updateJob → Quoted');
    await _callJob({'apiFunction': 'updateJob', 'jobId': j002, 'status': 'Quoted'});
    onLog('  ✓ Status: Quoted');

    onLog('  → createQuote');
    final quote = await _callQuote({
      'apiFunction': 'createQuote',
      'jobId': j002,
      'exclusions': ['Rock breaking', 'Site de-watering'],
      'assumptions': ['Level foundation provided', 'Access clear'],
      'validUntil': '2025-06-30',
      'notes': 'Subject to mortar colour selection',
    });
    final qId = quote['id'] as String;
    onLog('  ✓ Quote: $qId');

    onLog('  → addLineItem: Schist cladding 48m2 @ \$320');
    await _callLineItem({
      'apiFunction': 'addLineItem',
      'quoteId': qId,
      'description': 'Schist stone cladding — front elevation',
      'quantity': 48.0,
      'unit': 'm2',
      'rate': 320.0,
    });
    onLog('  → addLineItem: Feature wall 12m2 @ \$380');
    await _callLineItem({
      'apiFunction': 'addLineItem',
      'quoteId': qId,
      'description': 'Feature wall — entry',
      'quantity': 12.0,
      'unit': 'm2',
      'rate': 380.0,
    });
    onLog('  ✓ 2 line items added (total: \$${48 * 320 + 12 * 380})');

    onLog('  → Quote: sendDocument');
    await _callQuote({'apiFunction': 'sendDocument', 'quoteId': qId});
    onLog('  ✓ Quote: DocumentSent');
  }

  // ── J003 — 3 Tui Street (Enquiry) ────────────────────────────────────────────

  Future<void> _seedJ003() async {
    onLog('── J003 ──────────────────────────────────────');
    onLog('  → createJob (3 Tui Street)');
    final job = await _callJob({
      'apiFunction': 'createJob',
      'clientName': 'Heritage Builders NZ',
      'clientContactName': 'Julie Park',
      'siteAddress': '3 Tui Street, Hamilton',
      'description': 'Brick restoration — heritage villa',
    });
    onLog('  ✓ Job created (Enquiry): ${job['id']}');
  }

  // ── Manager call helpers ─────────────────────────────────────────────────────

  static const _jobQuery = r'''
    query($apiFunction: String!, $jobId: ID, $clientName: String,
          $clientContactName: String, $clientEmail: String,
          $clientPhone: String, $siteAddress: String,
          $description: String, $contractType: String,
          $paymentTerms: String, $status: String) {
      callJobManagerAPI(apiFunction: $apiFunction, jobId: $jobId,
        clientName: $clientName, clientContactName: $clientContactName,
        clientEmail: $clientEmail, clientPhone: $clientPhone,
        siteAddress: $siteAddress, description: $description,
        contractType: $contractType, paymentTerms: $paymentTerms,
        status: $status)
    }
  ''';

  static const _quoteQuery = r'''
    query($apiFunction: String!, $quoteId: ID, $jobId: ID,
          $exclusions: [String], $assumptions: [String],
          $validUntil: String, $notes: String,
          $deliveryMethod: String, $acceptedAt: String, $rejectedAt: String) {
      callQuoteManagerAPI(apiFunction: $apiFunction, quoteId: $quoteId,
        jobId: $jobId, exclusions: $exclusions, assumptions: $assumptions,
        validUntil: $validUntil, notes: $notes, deliveryMethod: $deliveryMethod,
        acceptedAt: $acceptedAt, rejectedAt: $rejectedAt)
    }
  ''';

  static const _lineItemQuery = r'''
    query($apiFunction: String!, $lineItemId: ID, $quoteId: ID,
          $description: String, $quantity: Float, $unit: String, $rate: Float) {
      callQuoteLineItemManagerAPI(apiFunction: $apiFunction,
        lineItemId: $lineItemId, quoteId: $quoteId,
        description: $description, quantity: $quantity,
        unit: $unit, rate: $rate)
    }
  ''';

  static const _variationQuery = r'''
    query($apiFunction: String!, $variationId: ID, $jobId: ID,
          $workPackageId: ID, $description: String, $reason: String,
          $clientInitiated: Boolean, $clientContactName: String,
          $price: Float, $timeImpactDays: Int,
          $deliveryMethod: String, $approvedAt: String,
          $declinedAt: String, $notes: String) {
      callVariationManagerAPI(apiFunction: $apiFunction,
        variationId: $variationId, jobId: $jobId,
        workPackageId: $workPackageId, description: $description,
        reason: $reason, clientInitiated: $clientInitiated,
        clientContactName: $clientContactName,
        price: $price, timeImpactDays: $timeImpactDays,
        deliveryMethod: $deliveryMethod, approvedAt: $approvedAt,
        declinedAt: $declinedAt, notes: $notes)
    }
  ''';

  static const _claimQuery = r'''
    query($apiFunction: String!, $claimId: ID, $stageId: ID, $jobId: ID,
          $periodDescription: String, $variationsIncluded: [String],
          $deliveryMethod: String, $paidAt: String,
          $paidAmount: Float, $notes: String) {
      callClaimManagerAPI(apiFunction: $apiFunction, claimId: $claimId,
        stageId: $stageId, jobId: $jobId,
        periodDescription: $periodDescription,
        variationsIncluded: $variationsIncluded,
        deliveryMethod: $deliveryMethod, paidAt: $paidAt,
        paidAmount: $paidAmount, notes: $notes)
    }
  ''';

  // Direct model mutations for models without a manager yet
  static const _createStageDoc = r'''
    mutation($input: CreateStageInput!) {
      createStage(input: $input) { id jobId description sequence status }
    }
  ''';

  static const _createWpDoc = r'''
    mutation($input: CreateWorkPackageInput!) {
      createWorkPackage(input: $input) { id jobId description status }
    }
  ''';

  // ── Cleanup ──────────────────────────────────────────────────────────────────

  /// Deletes all jobs and their children via the manager Lambda so seed() is idempotent.
  /// Uses callJobManagerAPI (Lambda-level auth) — direct model queries would require
  /// the user to be in the admin-manager Cognito group.
  Future<void> _clearAll() async {
    onLog('── Clearing existing data ─────────────────────');

    // listJobs returns a List, not a Map — decode manually.
    final request = GraphQLRequest<String>(
      document: _jobQuery,
      variables: {'apiFunction': 'listJobs'},
    );
    final response = await Amplify.API.query(request: request).response;
    _checkErrors(response.errors, 'callJobManagerAPI/listJobs');

    final raw = response.data;
    if (raw == null) {
      onLog('  (nothing to clear)');
      return;
    }
    final outer = jsonDecode(raw) as Map<String, dynamic>;
    final payload = jsonDecode(outer['callJobManagerAPI'] as String) as Map<String, dynamic>;
    if (payload['success'] != true) {
      throw Exception('listJobs failed: ${payload['message']}');
    }
    final jobs = (payload['data'] as List? ?? []).cast<Map<String, dynamic>>();

    if (jobs.isEmpty) {
      onLog('  (nothing to clear)');
      return;
    }

    onLog('  Found ${jobs.length} job(s) — deleting…');
    // deleteJob in the Lambda does the full cascade (stages, WPs, variations, claims, quotes).
    for (final job in jobs) {
      await _callJob({'apiFunction': 'deleteJob', 'jobId': job['id'] as String});
    }
    onLog('  ✓ Clear complete');
  }

  // ── Manager call helpers ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callJob(Map<String, dynamic> vars) =>
      _callManager(_jobQuery, vars, 'callJobManagerAPI');

  Future<Map<String, dynamic>> _callQuote(Map<String, dynamic> vars) =>
      _callManager(_quoteQuery, vars, 'callQuoteManagerAPI');

  Future<Map<String, dynamic>> _callLineItem(Map<String, dynamic> vars) =>
      _callManager(_lineItemQuery, vars, 'callQuoteLineItemManagerAPI');

  Future<Map<String, dynamic>> _callVariation(Map<String, dynamic> vars) =>
      _callManager(_variationQuery, vars, 'callVariationManagerAPI');

  Future<Map<String, dynamic>> _callClaim(Map<String, dynamic> vars) =>
      _callManager(_claimQuery, vars, 'callClaimManagerAPI');

  Future<Map<String, dynamic>> _createStage(Map<String, dynamic> fields) =>
      _mutate(_createStageDoc, {'input': fields}, 'createStage');

  Future<Map<String, dynamic>> _createWorkPackage(Map<String, dynamic> fields) =>
      _mutate(_createWpDoc, {'input': fields}, 'createWorkPackage');

  // ── Core GraphQL helpers ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callManager(
    String document,
    Map<String, dynamic> variables,
    String fieldName,
  ) async {
    final request = GraphQLRequest<String>(
      document: document,
      variables: variables,
    );
    final response = await Amplify.API.query(request: request).response;
    _checkErrors(response.errors, fieldName);

    final raw = response.data;
    if (raw == null) throw Exception('$fieldName returned null');

    // response.data is the full data envelope: '{"callJobManagerAPI":"<json string>"}'
    // The manager field value is itself a JSON string returned by ok()/fail().
    final outer = jsonDecode(raw) as Map<String, dynamic>;
    final fieldValue = outer[fieldName];
    if (fieldValue == null) throw Exception('$fieldName: no value in response envelope');

    final result = jsonDecode(fieldValue as String) as Map<String, dynamic>;
    if (result['success'] != true) {
      final errCode = result['error'] as String? ?? 'ERROR';
      final errMsg = result['message'] as String? ?? '';
      // If the Lambda caught an internal exception with a JSON body (e.g.
      // AppSync error array), parse and surface individual messages.
      if (errCode == 'INTERNAL_ERROR') {
        try {
          final inner = jsonDecode(errMsg) as Map<String, dynamic>;
          final gqlErrors = inner['errors'] as List?;
          if (gqlErrors != null && gqlErrors.isNotEmpty) {
            final lines = gqlErrors
                .map((e) => (e as Map)['message'] as String? ?? e.toString())
                .join('\n    ');
            throw Exception('$fieldName Lambda error:\n    $lines');
          }
        } catch (parseErr) {
          if (parseErr is Exception) rethrow;
        }
      }
      throw Exception('$errCode: $errMsg');
    }
    return (result['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
    String fieldName,
  ) async {
    final request = GraphQLRequest<String>(
      document: document,
      variables: variables,
    );
    final response = await Amplify.API.mutate(request: request).response;
    _checkErrors(response.errors, fieldName);

    final raw = response.data;
    if (raw == null) throw Exception('$fieldName returned null');

    final result = jsonDecode(raw) as Map<String, dynamic>;
    return (result[fieldName] as Map<String, dynamic>?) ?? {};
  }

  void _checkErrors(List<GraphQLResponseError> errors, String context) {
    if (errors.isNotEmpty) {
      // e.message can be a JS object on Flutter web, so we try extensions as well.
      final detail = errors.map((e) {
        final msg = e.message;
        if (msg != null && msg.isNotEmpty && msg != 'null' && msg != '[object Object]') {
          return msg;
        }
        final ext = e.extensions;
        if (ext != null && ext.isNotEmpty) return jsonEncode(ext);
        return e.toString();
      }).join(' | ');
      throw Exception('$context: $detail');
    }
  }
}
