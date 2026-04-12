import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/ModelProvider.dart';
import 'job_service.dart';
import 'quote_service.dart';

class SampleDataService {
  static Future<void> generateSampleData() async {
    try {
      // 1. Job: Enquiry stage
      final job1 = await JobService.createJob(
        jobName: 'Office Renovation - Level 5',
        client: 'TechCorp Industries',
        location: '123 Business Way, Auckland',
        description: 'Full floor fit-out including partitions, electrical, and plumbing.',
        contractValue: 0,
      );
      safePrint('Created Job 1 (Enquiry): ${job1.id}');

      // 2. Job: Quoted stage
      final job2 = await JobService.createJob(
        jobName: 'Residential Deck & Pergola',
        client: 'Jane Smith',
        location: '45 Suburban St, Ponsonby',
        description: 'New timber deck with custom steel pergola.',
        contractValue: 0,
      );
      final quote2 = await QuoteService.createQuote(
        jobId: job2.id,
        title: 'Main Construction Quote',
        validityDays: 30,
      );
      await QuoteService.addLineItem(
        quoteId: quote2.id,
        description: 'Timber Decking - Kwila',
        unit: 'm2',
        quantity: 45,
        rate: 350,
      );
      await QuoteService.addLineItem(
        quoteId: quote2.id,
        description: 'Steel Pergola Frame',
        unit: 'item',
        quantity: 1,
        rate: 4500,
      );
      await QuoteService.submitQuote(quote2.id);
      safePrint('Created Job 2 (Quoted): ${job2.id}');

      // 3. Job: Contracted stage (with Claims)
      final job3 = await JobService.createJob(
        jobName: 'New Build - Lot 12',
        client: 'Greenfield Developers',
        location: 'Lot 12, West Auckland Dev',
        description: 'Standard 4-bedroom residential build.',
        contractValue: 0,
      );
      final quote3 = await QuoteService.createQuote(
        jobId: job3.id,
        title: 'Full Build Quote',
        validityDays: 60,
      );
      await QuoteService.addLineItem(
        quoteId: quote3.id,
        description: 'Foundations and Slab',
        unit: 'm2',
        quantity: 180,
        rate: 280,
      );
      await QuoteService.addLineItem(
        quoteId: quote3.id,
        description: 'Timber Framing',
        unit: 'm3',
        quantity: 12,
        rate: 1800,
      );
      await QuoteService.submitQuote(quote3.id);
      await QuoteService.acceptQuote(quote3.id);
      safePrint('Created Job 3 (Contracted): ${job3.id}');

      // Create Claims for Job 3
      final claim1 = Claim(
        quoteId: quote3.id,
        claimNumber: 1,
        status: 'Approved',
        claimAmount: 15000,
        retention: 1500,
        netClaim: 13500,
        submittedAt: TemporalDateTime(DateTime.now().subtract(const Duration(days: 30))),
        approvedAt: TemporalDateTime(DateTime.now().subtract(const Duration(days: 25))),
      );
      
      final claim1Request = ModelMutations.create(claim1);
      // Construct a custom GraphQL document to avoid relationship nullability errors
      const String claim1OperationName = 'createClaim';
      const String claim1Document = r'''
        mutation CreateClaim($input: CreateClaimInput!) {
          createClaim(input: $input) {
            id
            quoteId
            claimNumber
            status
            claimAmount
            retention
            netClaim
            submittedAt
            approvedAt
            createdAt
            updatedAt
          }
        }
      ''';
      
      final claim1CustomRequest = GraphQLRequest<Claim>(
        document: claim1Document,
        variables: claim1Request.variables,
        modelType: Claim.classType,
        decodePath: claim1OperationName,
      );
      await Amplify.API.mutate(request: claim1CustomRequest).response;

      final claim2 = Claim(
        quoteId: quote3.id,
        claimNumber: 2,
        status: 'Submitted',
        claimAmount: 22000,
        retention: 2200,
        netClaim: 19800,
        submittedAt: TemporalDateTime.now(),
      );
      
      final claim2Request = ModelMutations.create(claim2);
      // Construct a custom GraphQL document to avoid relationship nullability errors
      const String claim2OperationName = 'createClaim';
      const String claim2Document = r'''
        mutation CreateClaim($input: CreateClaimInput!) {
          createClaim(input: $input) {
            id
            quoteId
            claimNumber
            status
            claimAmount
            retention
            netClaim
            submittedAt
            approvedAt
            createdAt
            updatedAt
          }
        }
      ''';
      
      final claim2CustomRequest = GraphQLRequest<Claim>(
        document: claim2Document,
        variables: claim2Request.variables,
        modelType: Claim.classType,
        decodePath: claim2OperationName,
      );
      await Amplify.API.mutate(request: claim2CustomRequest).response;
      safePrint('Created Claims for Job 3');

      // 4. Another Job: Enquiry stage
      await JobService.createJob(
        jobName: 'Kitchen Remodel',
        client: 'The Millers',
        location: '88 Heritage Rd, Epsom',
        description: 'High-end kitchen renovation with marble tops.',
      );
      safePrint('Created Job 4 (Enquiry)');

    } catch (e) {
      safePrint('Error generating sample data: $e');
    }
  }
}
