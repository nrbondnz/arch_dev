// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';

/** This is an auto generated class representing the Quote type in your schema. */
class Quote extends amplify_core.Model {
  static const classType = const _QuoteModelType();
  final String id;
  final String? _jobId;
  final Job? _job;
  final String? _title;
  final QuoteStatus? _status;
  final double? _subtotal;
  final double? _gstRate;
  final double? _totalIncGst;
  final String? _exclusions;
  final String? _notes;
  final int? _validityDays;
  final amplify_core.TemporalDateTime? _submittedAt;
  final amplify_core.TemporalDateTime? _acceptedAt;
  final List<QuoteLineItem>? _lineItems;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  QuoteModelIdentifier get modelIdentifier {
      return QuoteModelIdentifier(
        id: id
      );
  }
  
  String get jobId {
    return _jobId!;
  }
  
  Job? get job {
    return _job;
  }
  
  String get title {
    return _title!;
  }
  
  QuoteStatus get status {
    return _status!;
  }
  
  double? get subtotal {
    return _subtotal;
  }
  
  double? get gstRate {
    return _gstRate;
  }
  
  double? get totalIncGst {
    return _totalIncGst;
  }
  
  String? get exclusions {
    return _exclusions;
  }
  
  String? get notes {
    return _notes;
  }
  
  int? get validityDays {
    return _validityDays;
  }
  
  amplify_core.TemporalDateTime? get submittedAt {
    return _submittedAt;
  }
  
  amplify_core.TemporalDateTime? get acceptedAt {
    return _acceptedAt;
  }
  
  List<QuoteLineItem>? get lineItems {
    return _lineItems;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Quote._internal({required this.id, required jobId, job, required title, required status, subtotal, gstRate, totalIncGst, exclusions, notes, validityDays, submittedAt, acceptedAt, lineItems, createdAt, updatedAt}): _jobId = jobId, _job = job, _title = title, _status = status, _subtotal = subtotal, _gstRate = gstRate, _totalIncGst = totalIncGst, _exclusions = exclusions, _notes = notes, _validityDays = validityDays, _submittedAt = submittedAt, _acceptedAt = acceptedAt, _lineItems = lineItems, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Quote({String? id, required String jobId, Job? job, required String title, required QuoteStatus status, double? subtotal, double? gstRate, double? totalIncGst, String? exclusions, String? notes, int? validityDays, amplify_core.TemporalDateTime? submittedAt, amplify_core.TemporalDateTime? acceptedAt, List<QuoteLineItem>? lineItems}) {
    return Quote._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      jobId: jobId,
      job: job,
      title: title,
      status: status,
      subtotal: subtotal,
      gstRate: gstRate,
      totalIncGst: totalIncGst,
      exclusions: exclusions,
      notes: notes,
      validityDays: validityDays,
      submittedAt: submittedAt,
      acceptedAt: acceptedAt,
      lineItems: lineItems != null ? List<QuoteLineItem>.unmodifiable(lineItems) : lineItems);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Quote &&
      id == other.id &&
      _jobId == other._jobId &&
      _job == other._job &&
      _title == other._title &&
      _status == other._status &&
      _subtotal == other._subtotal &&
      _gstRate == other._gstRate &&
      _totalIncGst == other._totalIncGst &&
      _exclusions == other._exclusions &&
      _notes == other._notes &&
      _validityDays == other._validityDays &&
      _submittedAt == other._submittedAt &&
      _acceptedAt == other._acceptedAt &&
      const ListEquality().equals(_lineItems, other._lineItems);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Quote {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("jobId=" + "$_jobId" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("subtotal=" + (_subtotal != null ? _subtotal!.toString() : "null") + ", ");
    buffer.write("gstRate=" + (_gstRate != null ? _gstRate!.toString() : "null") + ", ");
    buffer.write("totalIncGst=" + (_totalIncGst != null ? _totalIncGst!.toString() : "null") + ", ");
    buffer.write("exclusions=" + "$_exclusions" + ", ");
    buffer.write("notes=" + "$_notes" + ", ");
    buffer.write("validityDays=" + (_validityDays != null ? _validityDays!.toString() : "null") + ", ");
    buffer.write("submittedAt=" + (_submittedAt != null ? _submittedAt!.format() : "null") + ", ");
    buffer.write("acceptedAt=" + (_acceptedAt != null ? _acceptedAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Quote copyWith({String? jobId, Job? job, String? title, QuoteStatus? status, double? subtotal, double? gstRate, double? totalIncGst, String? exclusions, String? notes, int? validityDays, amplify_core.TemporalDateTime? submittedAt, amplify_core.TemporalDateTime? acceptedAt, List<QuoteLineItem>? lineItems}) {
    return Quote._internal(
      id: id,
      jobId: jobId ?? this.jobId,
      job: job ?? this.job,
      title: title ?? this.title,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      gstRate: gstRate ?? this.gstRate,
      totalIncGst: totalIncGst ?? this.totalIncGst,
      exclusions: exclusions ?? this.exclusions,
      notes: notes ?? this.notes,
      validityDays: validityDays ?? this.validityDays,
      submittedAt: submittedAt ?? this.submittedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      lineItems: lineItems ?? this.lineItems);
  }
  
  Quote copyWithModelFieldValues({
    ModelFieldValue<String>? jobId,
    ModelFieldValue<Job?>? job,
    ModelFieldValue<String>? title,
    ModelFieldValue<QuoteStatus>? status,
    ModelFieldValue<double?>? subtotal,
    ModelFieldValue<double?>? gstRate,
    ModelFieldValue<double?>? totalIncGst,
    ModelFieldValue<String?>? exclusions,
    ModelFieldValue<String?>? notes,
    ModelFieldValue<int?>? validityDays,
    ModelFieldValue<amplify_core.TemporalDateTime?>? submittedAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? acceptedAt,
    ModelFieldValue<List<QuoteLineItem>?>? lineItems
  }) {
    return Quote._internal(
      id: id,
      jobId: jobId == null ? this.jobId : jobId.value,
      job: job == null ? this.job : job.value,
      title: title == null ? this.title : title.value,
      status: status == null ? this.status : status.value,
      subtotal: subtotal == null ? this.subtotal : subtotal.value,
      gstRate: gstRate == null ? this.gstRate : gstRate.value,
      totalIncGst: totalIncGst == null ? this.totalIncGst : totalIncGst.value,
      exclusions: exclusions == null ? this.exclusions : exclusions.value,
      notes: notes == null ? this.notes : notes.value,
      validityDays: validityDays == null ? this.validityDays : validityDays.value,
      submittedAt: submittedAt == null ? this.submittedAt : submittedAt.value,
      acceptedAt: acceptedAt == null ? this.acceptedAt : acceptedAt.value,
      lineItems: lineItems == null ? this.lineItems : lineItems.value
    );
  }
  
  Quote.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _jobId = json['jobId'],
      _job = json['job'] != null
        ? Job.fromJson(new Map<String, dynamic>.from(json['job']['serializedData']))
        : null,
      _title = json['title'],
      _status = amplify_core.enumFromString<QuoteStatus>(json['status'], QuoteStatus.values),
      _subtotal = (json['subtotal'] as num?)?.toDouble(),
      _gstRate = (json['gstRate'] as num?)?.toDouble(),
      _totalIncGst = (json['totalIncGst'] as num?)?.toDouble(),
      _exclusions = json['exclusions'],
      _notes = json['notes'],
      _validityDays = (json['validityDays'] as num?)?.toInt(),
      _submittedAt = json['submittedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['submittedAt']) : null,
      _acceptedAt = json['acceptedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['acceptedAt']) : null,
      _lineItems = json['lineItems'] is List
        ? (json['lineItems'] as List)
          .where((e) => e?['serializedData'] != null)
          .map((e) => QuoteLineItem.fromJson(new Map<String, dynamic>.from(e['serializedData'])))
          .toList()
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'jobId': _jobId, 'job': _job?.toJson(), 'title': _title, 'status': amplify_core.enumToString(_status), 'subtotal': _subtotal, 'gstRate': _gstRate, 'totalIncGst': _totalIncGst, 'exclusions': _exclusions, 'notes': _notes, 'validityDays': _validityDays, 'submittedAt': _submittedAt?.format(), 'acceptedAt': _acceptedAt?.format(), 'lineItems': _lineItems?.map((QuoteLineItem e) => e.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'jobId': _jobId,
    'job': _job,
    'title': _title,
    'status': _status,
    'subtotal': _subtotal,
    'gstRate': _gstRate,
    'totalIncGst': _totalIncGst,
    'exclusions': _exclusions,
    'notes': _notes,
    'validityDays': _validityDays,
    'submittedAt': _submittedAt,
    'acceptedAt': _acceptedAt,
    'lineItems': _lineItems,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<QuoteModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<QuoteModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final JOBID = amplify_core.QueryField(fieldName: "jobId");
  static final JOB = amplify_core.QueryField(
    fieldName: "job",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Job'));
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final SUBTOTAL = amplify_core.QueryField(fieldName: "subtotal");
  static final GSTRATE = amplify_core.QueryField(fieldName: "gstRate");
  static final TOTALINCGST = amplify_core.QueryField(fieldName: "totalIncGst");
  static final EXCLUSIONS = amplify_core.QueryField(fieldName: "exclusions");
  static final NOTES = amplify_core.QueryField(fieldName: "notes");
  static final VALIDITYDAYS = amplify_core.QueryField(fieldName: "validityDays");
  static final SUBMITTEDAT = amplify_core.QueryField(fieldName: "submittedAt");
  static final ACCEPTEDAT = amplify_core.QueryField(fieldName: "acceptedAt");
  static final LINEITEMS = amplify_core.QueryField(
    fieldName: "lineItems",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'QuoteLineItem'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Quote";
    modelSchemaDefinition.pluralName = "Quotes";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: const ["main-contractor"],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: const ["qs"],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["status"], name: "quotesByStatus")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.JOBID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Quote.JOB,
      isRequired: false,
      targetNames: ["jobId"],
      ofModelName: 'Job'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.SUBTOTAL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.GSTRATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.TOTALINCGST,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.EXCLUSIONS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.NOTES,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.VALIDITYDAYS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.SUBMITTEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Quote.ACCEPTEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Quote.LINEITEMS,
      isRequired: false,
      ofModelName: 'QuoteLineItem',
      associatedKey: QuoteLineItem.QUOTEID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _QuoteModelType extends amplify_core.ModelType<Quote> {
  const _QuoteModelType();
  
  @override
  Quote fromJson(Map<String, dynamic> jsonData) {
    return Quote.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Quote';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Quote] in your schema.
 */
class QuoteModelIdentifier implements amplify_core.ModelIdentifier<Quote> {
  final String id;

  /** Create an instance of QuoteModelIdentifier using [id] the primary key. */
  const QuoteModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'QuoteModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is QuoteModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}
