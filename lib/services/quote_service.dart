import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/ModelProvider.dart';
import 'job_service.dart';

class QuoteService {
  /// Creates a new Draft quote for the given job.
  static Future<Quote> createQuote({
    required String jobId,
    required String title,
    String? exclusions,
    String? notes,
    int validityDays = 30,
    double gstRate = 0.15,
  }) async {
    final quote = Quote(
      jobId: jobId,
      title: title,
      status: QuoteStatus.Draft,
      subtotal: 0,
      gstRate: gstRate,
      totalIncGst: 0,
      exclusions: exclusions,
      notes: notes,
      validityDays: validityDays,
    );

    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'createQuote';
    const String document = '''
      mutation CreateQuote(\$input: CreateQuoteInput!) {
        $operationName(input: \$input) {
          id
          jobId
          title
          status
          subtotal
          gstRate
          totalIncGst
          exclusions
          notes
          validityDays
          submittedAt
          acceptedAt
          createdAt
          updatedAt
        }
      }
    ''';
    
    final GraphQLRequest<Quote> customRequest = GraphQLRequest<Quote>(
      document: document,
      variables: request.variables,
      modelType: Quote.classType,
      decodePath: operationName,
    );

    final response = await Amplify.API.mutate(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to create quote: ${response.errors}');
    }
    return response.data!;
  }

  /// Fetches a single quote by ID.
  static Future<Quote?> getQuote(String quoteId) async {
    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'getQuote';
    const String document = '''
      query GetQuote(\$id: ID!) {
        $operationName(id: \$id) {
          id
          jobId
          title
          status
          subtotal
          gstRate
          totalIncGst
          exclusions
          notes
          validityDays
          submittedAt
          acceptedAt
          createdAt
          updatedAt
        }
      }
    ''';

    final GraphQLRequest<Quote> customRequest = GraphQLRequest<Quote>(
      document: document,
      variables: request.variables,
      modelType: Quote.classType,
      decodePath: operationName,
    );

    final response = await Amplify.API.query(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to get quote: ${response.errors}');
    }
    return response.data;
  }

  /// Lists all quotes for a specific job.
  static Future<List<Quote>> listQuotesForJob(String jobId) async {
    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'listQuotes';
    const String document = '''
      query ListQuotes(\$filter: ModelQuoteFilterInput, \$limit: Int, \$nextToken: String) {
        $operationName(filter: \$filter, limit: \$limit, nextToken: \$nextToken) {
          items {
            id
            jobId
            title
            status
            subtotal
            gstRate
            totalIncGst
            exclusions
            notes
            validityDays
            submittedAt
            acceptedAt
            createdAt
            updatedAt
          }
          nextToken
        }
      }
    ''';

    final GraphQLRequest<PaginatedResult<Quote>> customRequest =
        GraphQLRequest<PaginatedResult<Quote>>(
      document: document,
      variables: request.variables,
      modelType: const PaginatedModelType(Quote.classType),
      decodePath: operationName,
    );

    final response = await Amplify.API.query(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to list quotes: ${response.errors}');
    }
    return response.data?.items.whereType<Quote>().toList() ?? [];
  }

  /// Lists all quotes with the given status (e.g. for MC dashboard).
  static Future<List<Quote>> listQuotesByStatus(QuoteStatus status) async {
    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'listQuotes';
    const String document = '''
      query ListQuotes(\$filter: ModelQuoteFilterInput, \$limit: Int, \$nextToken: String) {
        $operationName(filter: \$filter, limit: \$limit, nextToken: \$nextToken) {
          items {
            id
            jobId
            title
            status
            subtotal
            gstRate
            totalIncGst
            exclusions
            notes
            validityDays
            submittedAt
            acceptedAt
            createdAt
            updatedAt
          }
          nextToken
        }
      }
    ''';

    final GraphQLRequest<PaginatedResult<Quote>> customRequest =
        GraphQLRequest<PaginatedResult<Quote>>(
      document: document,
      variables: request.variables,
      modelType: const PaginatedModelType(Quote.classType),
      decodePath: operationName,
    );

    final response = await Amplify.API.query(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to list quotes by status: ${response.errors}');
    }
    return response.data?.items.whereType<Quote>().toList() ?? [];
  }

  /// Updates a draft quote's metadata (exclusions, notes, title).
  static Future<Quote> updateQuote(Quote quote) async {
    if (quote.status != QuoteStatus.Draft) {
      throw StateError('Only Draft quotes can be edited');
    }

    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'updateQuote';
    const String document = '''
      mutation UpdateQuote(\$input: UpdateQuoteInput!, \$condition: ModelQuoteConditionInput) {
        $operationName(input: \$input, condition: \$condition) {
          id
          jobId
          title
          status
          subtotal
          gstRate
          totalIncGst
          exclusions
          notes
          validityDays
          submittedAt
          acceptedAt
          createdAt
          updatedAt
        }
      }
    ''';

    final GraphQLRequest<Quote> customRequest = GraphQLRequest<Quote>(
      document: document,
      variables: request.variables,
      modelType: Quote.classType,
      decodePath: operationName,
    );

    final response = await Amplify.API.mutate(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to update quote: ${response.errors}');
    }
    return response.data!;
  }

  // ── Line Item Operations ────────────────────────────────────────────────

  /// Adds a line item to a quote and recalculates totals.
  static Future<QuoteLineItem> addLineItem({
    required String quoteId,
    required String description,
    required String unit,
    required double quantity,
    required double rate,
  }) async {
    final total = quantity * rate;
    final item = QuoteLineItem(
      quoteId: quoteId,
      description: description,
      unit: unit,
      quantity: quantity,
      rate: rate,
      total: total,
    );

    // Construct a custom GraphQL document to avoid relationship nullability errors
    const String operationName = 'createQuoteLineItem';
    const String document = '''
      mutation CreateQuoteLineItem(\$input: CreateQuoteLineItemInput!) {
        $operationName(input: \$input) {
          id
          quoteId
          description
          unit
          quantity
          rate
          total
          createdAt
          updatedAt
        }
      }
    ''';

    final GraphQLRequest<QuoteLineItem> customRequest = GraphQLRequest<QuoteLineItem>(
      document: document,
      variables: request.variables,
      modelType: QuoteLineItem.classType,
      decodePath: operationName,
    );

    final response = await Amplify.API.mutate(request: customRequest).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to add line item: ${response.errors}');
    }

    await recalculateTotals(quoteId);
    return response.data!;
  }

  /// Removes a line item and recalculates the quote totals.
  static Future<void> removeLineItem(
    QuoteLineItem item,
    String quoteId,
  ) async {
    final request = ModelMutations.delete(item);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to remove line item: ${response.errors}');
    }

    await recalculateTotals(quoteId);
  }

  /// Lists all line items for a quote.
  static Future<List<QuoteLineItem>> listLineItems(String quoteId) async {
    final request = ModelQueries.list(
      QuoteLineItem.classType,
      where: QuoteLineItem.QUOTEID.eq(quoteId),
    );
    final response = await Amplify.API.query(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to list line items: ${response.errors}');
    }
    return response.data?.items.whereType<QuoteLineItem>().toList() ?? [];
  }

  // ── Status Transitions ──────────────────────────────────────────────────

  /// Submits a draft quote (FR-11: Draft → Submitted).
  /// Also transitions the job from Enquiry → Quoted.
  /// Throws if either the quote or job update fails — no partial state.
  static Future<Quote> submitQuote(String quoteId) async {
    final quote = await getQuote(quoteId);
    if (quote == null) throw Exception('Quote not found');
    if (quote.status != QuoteStatus.Draft) {
      throw StateError('Only Draft quotes can be submitted (FR-11)');
    }

    // Move the job to Quoted FIRST if it's still in Enquiry.
    // If this fails we haven't changed the quote yet, so state is consistent.
    final job = await JobService.getJob(quote.jobId);
    if (job == null) throw Exception('Job not found for quote');
    if (job.status == JobStatus.Enquiry) {
      await JobService.updateJobStatus(job, JobStatus.Quoted);
    }

    final now = TemporalDateTime.now();
    final updated = quote.copyWith(
      status: QuoteStatus.Submitted,
      submittedAt: now,
    );

    final request = ModelMutations.update(updated);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      // Attempt to roll back the job status change
      try {
        final freshJob = await JobService.getJob(quote.jobId);
        if (freshJob != null && freshJob.status == JobStatus.Quoted) {
          // Best-effort rollback — if this also fails, admin intervention needed
          final rollback = freshJob.copyWith(status: JobStatus.Enquiry);
          await Amplify.API.mutate(request: ModelMutations.update(rollback)).response;
        }
      } on Exception {
        // Rollback failed; log but throw original error
      }
      throw Exception('Failed to submit quote: ${response.errors}');
    }

    return response.data!;
  }

  /// Accepts a submitted quote (FR-11: Submitted → Accepted).
  /// Enforces FR-12: only one accepted quote per job.
  /// Enforces FR-67: quote must not be expired (validityDays).
  /// Updates job contract value and transitions to Contracted (FR-68).
  /// Throws if any step fails — no partial state.
  ///
  /// NOTE: FR-12 is enforced client-side only. A backend-level guard
  /// (e.g. DynamoDB conditional write or AppSync resolver) would be
  /// needed to prevent concurrent acceptance of two quotes.
  static Future<Quote> acceptQuote(String quoteId) async {
    final quote = await getQuote(quoteId);
    if (quote == null) throw Exception('Quote not found');
    if (quote.status != QuoteStatus.Submitted) {
      throw StateError('Only Submitted quotes can be accepted (FR-11)');
    }

    // FR-67: check quote validity period has not expired
    if (quote.submittedAt != null && quote.validityDays != null) {
      final submittedDate = DateTime.parse(quote.submittedAt!.toString());
      final expiryDate = submittedDate.add(Duration(days: quote.validityDays!));
      if (DateTime.now().isAfter(expiryDate)) {
        throw StateError(
          'This quote has expired (submitted ${quote.submittedAt}, '
          'validity ${quote.validityDays} days) (FR-67)',
        );
      }
    }

    // FR-12: check no other accepted quote exists for this job
    final jobQuotes = await listQuotesForJob(quote.jobId);
    final alreadyAccepted = jobQuotes.any((q) => q.status == QuoteStatus.Accepted);
    if (alreadyAccepted) {
      throw StateError(
        'This job already has an accepted quote (FR-12)',
      );
    }

    // Update the quote first
    final now = TemporalDateTime.now();
    final updated = quote.copyWith(
      status: QuoteStatus.Accepted,
      acceptedAt: now,
    );

    final request = ModelMutations.update(updated);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to accept quote: ${response.errors}');
    }

    // Update job contract value and transition to Contracted (FR-68).
    // Pass hasAcceptedQuote=true since we just accepted it above.
    final job = await JobService.getJob(quote.jobId);
    if (job == null) throw Exception('Job not found for quote');
    if (job.status == JobStatus.Quoted) {
      try {
        await JobService.updateJobStatus(
          job,
          JobStatus.Contracted,
          contractValue: quote.subtotal,
          hasAcceptedQuote: true,
        );
      } on Exception catch (e) {
        // Job update failed after quote was already accepted.
        // Roll back the quote to Submitted to keep state consistent.
        try {
          final rollback = updated.copyWith(
            status: QuoteStatus.Submitted,
            acceptedAt: null,
          );
          await Amplify.API.mutate(request: ModelMutations.update(rollback)).response;
        } on Exception {
          // Rollback also failed — system is in inconsistent state
          safePrint('CRITICAL: quote accepted but job update and rollback both failed');
        }
        throw Exception('Failed to update job after accepting quote: $e');
      }
    }

    return response.data!;
  }

  /// Rejects a submitted quote (FR-11: Submitted → Rejected).
  static Future<Quote> rejectQuote(String quoteId) async {
    final quote = await getQuote(quoteId);
    if (quote == null) throw Exception('Quote not found');
    if (quote.status != QuoteStatus.Submitted) {
      throw StateError('Only Submitted quotes can be rejected (FR-11)');
    }

    final updated = quote.copyWith(status: QuoteStatus.Rejected);

    final request = ModelMutations.update(updated);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception('Failed to reject quote: ${response.errors}');
    }
    return response.data!;
  }

  // ── Totals (FR-13) ─────────────────────────────────────────────────────

  /// Recalculates subtotal and totalIncGst from line items.
  static Future<void> recalculateTotals(String quoteId) async {
    final items = await listLineItems(quoteId);
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);

    final quote = await getQuote(quoteId);
    if (quote == null) return;

    final gstRate = quote.gstRate ?? 0.15;
    final totalIncGst = subtotal * (1 + gstRate);

    final updated = quote.copyWith(
      subtotal: subtotal,
      totalIncGst: totalIncGst,
    );

    final request = ModelMutations.update(updated);
    await Amplify.API.mutate(request: request).response;
  }

  // ── Bulk Save (for QuoteBuilderScreen) ──────────────────────────────────

  /// Saves a quote with all its line items in one logical operation.
  /// Creates the quote if [quoteId] is null, otherwise updates it.
  /// Returns the saved quote.
  static Future<Quote> saveQuoteWithLineItems({
    String? quoteId,
    required String jobId,
    required String title,
    String? exclusions,
    String? notes,
    required List<LineItemData> lineItems,
    double gstRate = 0.15,
  }) async {
    // Create or update the quote
    Quote quote;
    if (quoteId == null) {
      quote = await createQuote(
        jobId: jobId,
        title: title,
        exclusions: exclusions,
        notes: notes,
        gstRate: gstRate,
      );
    } else {
      final existing = await getQuote(quoteId);
      if (existing == null) throw Exception('Quote not found');
      quote = await updateQuote(existing.copyWith(
        title: title,
        exclusions: exclusions,
        notes: notes,
      ));
    }

    // Delete existing line items (replace all)
    final existingItems = await listLineItems(quote.id);
    for (final item in existingItems) {
      final req = ModelMutations.delete(item);
      await Amplify.API.mutate(request: req).response;
    }

    // Create new line items
    for (final li in lineItems) {
      await addLineItem(
        quoteId: quote.id,
        description: li.description,
        unit: li.unit,
        quantity: li.quantity,
        rate: li.rate,
      );
    }

    // Return the quote with updated totals
    return (await getQuote(quote.id))!;
  }
}

/// Data transfer object for line items before they're persisted.
class LineItemData {
  final String description;
  final String unit;
  final double quantity;
  final double rate;

  const LineItemData({
    required this.description,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;
}
