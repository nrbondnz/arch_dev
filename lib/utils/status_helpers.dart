import 'package:flutter/material.dart';

import '../models/ModelProvider.dart';

/// Returns the display label for a [JobStatus] value.
String jobStatusLabel(JobStatus status) => switch (status) {
      JobStatus.Enquiry => 'Enquiry',
      JobStatus.Quoted => 'Quoted',
      JobStatus.Contracted => 'Contracted',
    };

/// Returns the badge colour for a [JobStatus] value.
Color jobStatusColor(JobStatus status) => switch (status) {
      JobStatus.Enquiry => Colors.orange,
      JobStatus.Quoted => Colors.blue,
      JobStatus.Contracted => Colors.green,
    };

/// Returns the display label for a [QuoteStatus] value.
String quoteStatusLabel(QuoteStatus status) => switch (status) {
      QuoteStatus.Draft => 'Draft',
      QuoteStatus.Submitted => 'Submitted',
      QuoteStatus.Accepted => 'Accepted',
      QuoteStatus.Rejected => 'Rejected',
    };

/// Returns the badge colour for a [QuoteStatus] value.
Color quoteStatusColor(QuoteStatus status) => switch (status) {
      QuoteStatus.Draft => Colors.grey,
      QuoteStatus.Submitted => Colors.blue,
      QuoteStatus.Accepted => Colors.green,
      QuoteStatus.Rejected => Colors.red,
    };
