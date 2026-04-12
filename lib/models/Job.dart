// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';

/** This is an auto generated class representing the Job type in your schema. */
class Job extends amplify_core.Model {
  static const classType = const _JobModelType();
  final String id;
  final String? _jobName;
  final String? _client;
  final String? _location;
  final String? _description;
  final JobStatus? _status;
  final double? _contractValue;
  final List<Quote>? _quotes;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  JobModelIdentifier get modelIdentifier {
      return JobModelIdentifier(
        id: id
      );
  }
  
  String get jobName {
    return _jobName!;
  }
  
  String get client {
    return _client!;
  }
  
  String? get location {
    return _location;
  }
  
  String? get description {
    return _description;
  }
  
  JobStatus get status {
    return _status!;
  }
  
  double? get contractValue {
    return _contractValue;
  }
  
  List<Quote>? get quotes {
    return _quotes;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Job._internal({required this.id, required jobName, required client, location, description, required status, contractValue, quotes, createdAt, updatedAt}): _jobName = jobName, _client = client, _location = location, _description = description, _status = status, _contractValue = contractValue, _quotes = quotes, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Job({String? id, required String jobName, required String client, String? location, String? description, required JobStatus status, double? contractValue, List<Quote>? quotes}) {
    return Job._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      jobName: jobName,
      client: client,
      location: location,
      description: description,
      status: status,
      contractValue: contractValue,
      quotes: quotes != null ? List<Quote>.unmodifiable(quotes) : quotes);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Job &&
      id == other.id &&
      _jobName == other._jobName &&
      _client == other._client &&
      _location == other._location &&
      _description == other._description &&
      _status == other._status &&
      _contractValue == other._contractValue &&
      const ListEquality().equals(_quotes, other._quotes);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Job {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("jobName=" + "$_jobName" + ", ");
    buffer.write("client=" + "$_client" + ", ");
    buffer.write("location=" + "$_location" + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("contractValue=" + (_contractValue != null ? _contractValue!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Job copyWith({String? jobName, String? client, String? location, String? description, JobStatus? status, double? contractValue, List<Quote>? quotes}) {
    return Job._internal(
      id: id,
      jobName: jobName ?? this.jobName,
      client: client ?? this.client,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      contractValue: contractValue ?? this.contractValue,
      quotes: quotes ?? this.quotes);
  }
  
  Job copyWithModelFieldValues({
    ModelFieldValue<String>? jobName,
    ModelFieldValue<String>? client,
    ModelFieldValue<String?>? location,
    ModelFieldValue<String?>? description,
    ModelFieldValue<JobStatus>? status,
    ModelFieldValue<double?>? contractValue,
    ModelFieldValue<List<Quote>?>? quotes
  }) {
    return Job._internal(
      id: id,
      jobName: jobName == null ? this.jobName : jobName.value,
      client: client == null ? this.client : client.value,
      location: location == null ? this.location : location.value,
      description: description == null ? this.description : description.value,
      status: status == null ? this.status : status.value,
      contractValue: contractValue == null ? this.contractValue : contractValue.value,
      quotes: quotes == null ? this.quotes : quotes.value
    );
  }
  
  Job.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _jobName = json['jobName'],
      _client = json['client'],
      _location = json['location'],
      _description = json['description'],
      _status = amplify_core.enumFromString<JobStatus>(json['status'], JobStatus.values),
      _contractValue = (json['contractValue'] as num?)?.toDouble(),
      _quotes = json['quotes'] is List
        ? (json['quotes'] as List)
          .where((e) => e?['serializedData'] != null)
          .map((e) => Quote.fromJson(new Map<String, dynamic>.from(e['serializedData'])))
          .toList()
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'jobName': _jobName, 'client': _client, 'location': _location, 'description': _description, 'status': amplify_core.enumToString(_status), 'contractValue': _contractValue, 'quotes': _quotes?.map((Quote e) => e.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'jobName': _jobName,
    'client': _client,
    'location': _location,
    'description': _description,
    'status': _status,
    'contractValue': _contractValue,
    'quotes': _quotes,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<JobModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<JobModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final JOBNAME = amplify_core.QueryField(fieldName: "jobName");
  static final CLIENT = amplify_core.QueryField(fieldName: "client");
  static final LOCATION = amplify_core.QueryField(fieldName: "location");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final CONTRACTVALUE = amplify_core.QueryField(fieldName: "contractValue");
  static final QUOTES = amplify_core.QueryField(
    fieldName: "quotes",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Quote'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Job";
    modelSchemaDefinition.pluralName = "Jobs";
    
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
        groups: const ["main-contractor", "qs"],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["status"], name: "jobsByStatus")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.JOBNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.CLIENT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.LOCATION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Job.CONTRACTVALUE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Job.QUOTES,
      isRequired: false,
      ofModelName: 'Quote',
      associatedKey: Quote.JOBID
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

class _JobModelType extends amplify_core.ModelType<Job> {
  const _JobModelType();
  
  @override
  Job fromJson(Map<String, dynamic> jsonData) {
    return Job.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Job';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Job] in your schema.
 */
class JobModelIdentifier implements amplify_core.ModelIdentifier<Job> {
  final String id;

  /** Create an instance of JobModelIdentifier using [id] the primary key. */
  const JobModelIdentifier({
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
  String toString() => 'JobModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is JobModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}
