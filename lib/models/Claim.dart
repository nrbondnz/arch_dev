// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;

/** This is an auto generated class representing the Claim type in your schema. */
class Claim extends amplify_core.Model {
  static const classType = const _ClaimModelType();
  final String id;
  final String? _quoteId;
  final int? _claimNumber;
  final String? _status;
  final double? _claimAmount;
  final double? _retention;
  final double? _netClaim;
  final amplify_core.TemporalDateTime? _submittedAt;
  final amplify_core.TemporalDateTime? _approvedAt;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @override
  String getId() => id;
  
  ClaimModelIdentifier get modelIdentifier {
      return ClaimModelIdentifier(
        id: id
      );
  }
  
  String get quoteId {
    return _quoteId!;
  }
  
  int get claimNumber {
    return _claimNumber!;
  }
  
  String? get status {
    return _status;
  }
  
  double get claimAmount {
    return _claimAmount!;
  }
  
  double? get retention {
    return _retention;
  }
  
  double get netClaim {
    return _netClaim!;
  }
  
  amplify_core.TemporalDateTime? get submittedAt {
    return _submittedAt;
  }
  
  amplify_core.TemporalDateTime? get approvedAt {
    return _approvedAt;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Claim._internal({required this.id, required quoteId, required claimNumber, status, required claimAmount, retention, required netClaim, submittedAt, approvedAt, createdAt, updatedAt}): _quoteId = quoteId, _claimNumber = claimNumber, _status = status, _claimAmount = claimAmount, _retention = retention, _netClaim = netClaim, _submittedAt = submittedAt, _approvedAt = approvedAt, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Claim({String? id, required String quoteId, required int claimNumber, String? status, required double claimAmount, double? retention, required double netClaim, amplify_core.TemporalDateTime? submittedAt, amplify_core.TemporalDateTime? approvedAt}) {
    return Claim._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      quoteId: quoteId,
      claimNumber: claimNumber,
      status: status,
      claimAmount: claimAmount,
      retention: retention,
      netClaim: netClaim,
      submittedAt: submittedAt,
      approvedAt: approvedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Claim &&
      id == other.id &&
      _quoteId == other._quoteId &&
      _claimNumber == other._claimNumber &&
      _status == other._status &&
      _claimAmount == other._claimAmount &&
      _retention == other._retention &&
      _netClaim == other._netClaim &&
      _submittedAt == other._submittedAt &&
      _approvedAt == other._approvedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Claim {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("quoteId=" + "$_quoteId" + ", ");
    buffer.write("claimNumber=" + (_claimNumber != null ? _claimNumber!.toString() : "null") + ", ");
    buffer.write("status=" + "$_status" + ", ");
    buffer.write("claimAmount=" + (_claimAmount != null ? _claimAmount!.toString() : "null") + ", ");
    buffer.write("retention=" + (_retention != null ? _retention!.toString() : "null") + ", ");
    buffer.write("netClaim=" + (_netClaim != null ? _netClaim!.toString() : "null") + ", ");
    buffer.write("submittedAt=" + (_submittedAt != null ? _submittedAt!.format() : "null") + ", ");
    buffer.write("approvedAt=" + (_approvedAt != null ? _approvedAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Claim copyWith({String? id, String? quoteId, int? claimNumber, String? status, double? claimAmount, double? retention, double? netClaim, amplify_core.TemporalDateTime? submittedAt, amplify_core.TemporalDateTime? approvedAt}) {
    return Claim._internal(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      claimNumber: claimNumber ?? this.claimNumber,
      status: status ?? this.status,
      claimAmount: claimAmount ?? this.claimAmount,
      retention: retention ?? this.retention,
      netClaim: netClaim ?? this.netClaim,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt);
  }
  
  Claim.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _quoteId = json['quoteId'],
      _claimNumber = (json['claimNumber'] as num?)?.toInt(),
      _status = json['status'],
      _claimAmount = (json['claimAmount'] as num?)?.toDouble(),
      _retention = (json['retention'] as num?)?.toDouble(),
      _netClaim = (json['netClaim'] as num?)?.toDouble(),
      _submittedAt = json['submittedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['submittedAt']) : null,
      _approvedAt = json['approvedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['approvedAt']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'quoteId': _quoteId, 'claimNumber': _claimNumber, 'status': _status, 'claimAmount': _claimAmount, 'retention': _retention, 'netClaim': _netClaim, 'submittedAt': _submittedAt?.format(), 'approvedAt': _approvedAt?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id, 'quoteId': _quoteId, 'claimNumber': _claimNumber, 'status': _status, 'claimAmount': _claimAmount, 'retention': _retention, 'netClaim': _netClaim, 'submittedAt': _submittedAt, 'approvedAt': _approvedAt, 'createdAt': _createdAt, 'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ClaimModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ClaimModelIdentifier>();
  static final amplify_core.QueryField ID = amplify_core.QueryField(fieldName: "id");
  static final amplify_core.QueryField QUOTEID = amplify_core.QueryField(fieldName: "quoteId");
  static final amplify_core.QueryField CLAIMNUMBER = amplify_core.QueryField(fieldName: "claimNumber");
  static final amplify_core.QueryField STATUS = amplify_core.QueryField(fieldName: "status");
  static final amplify_core.QueryField CLAIMAMOUNT = amplify_core.QueryField(fieldName: "claimAmount");
  static final amplify_core.QueryField RETENTION = amplify_core.QueryField(fieldName: "retention");
  static final amplify_core.QueryField NETCLAIM = amplify_core.QueryField(fieldName: "netClaim");
  static final amplify_core.QueryField SUBMITTEDAT = amplify_core.QueryField(fieldName: "submittedAt");
  static final amplify_core.QueryField APPROVEDAT = amplify_core.QueryField(fieldName: "approvedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Claim";
    modelSchemaDefinition.pluralName = "Claims";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "main-contractor" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "qs" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["status"], name: "claimsByStatus")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.QUOTEID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.CLAIMNUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.STATUS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.CLAIMAMOUNT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.RETENTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.NETCLAIM,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.SUBMITTEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Claim.APPROVEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
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

class _ClaimModelType extends amplify_core.ModelType<Claim> {
  const _ClaimModelType();
  
  @override
  Claim fromJson(Map<String, dynamic> json) {
    return Claim.fromJson(json);
  }
  
  @override
  String modelName() {
    return 'Claim';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Claim] in your schema.
 */
class ClaimModelIdentifier implements amplify_core.ModelIdentifier<Claim> {
  final String id;

  /** Create an instance of ClaimModelIdentifier using [id] of the item. */
  const ClaimModelIdentifier({
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
  String toString() => 'ClaimModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ClaimModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}
