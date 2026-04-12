// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;

/** This is an auto generated class representing the QuoteLineItem type in your schema. */
class QuoteLineItem extends amplify_core.Model {
  static const classType = const _QuoteLineItemModelType();
  final String id;
  final String? _quoteId;
  final Quote? _quote;
  final String? _description;
  final String? _unit;
  final double? _quantity;
  final double? _rate;
  final double? _total;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  QuoteLineItemModelIdentifier get modelIdentifier {
      return QuoteLineItemModelIdentifier(
        id: id
      );
  }
  
  String get quoteId {
    return _quoteId!;
  }
  
  Quote? get quote {
    return _quote;
  }
  
  String get description {
    return _description!;
  }
  
  String? get unit {
    return _unit;
  }
  
  double get quantity {
    return _quantity!;
  }
  
  double get rate {
    return _rate!;
  }
  
  double get total {
    return _total!;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const QuoteLineItem._internal({required this.id, required quoteId, quote, required description, unit, required quantity, required rate, required total, createdAt, updatedAt}): _quoteId = quoteId, _quote = quote, _description = description, _unit = unit, _quantity = quantity, _rate = rate, _total = total, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory QuoteLineItem({String? id, required String quoteId, Quote? quote, required String description, String? unit, required double quantity, required double rate, required double total}) {
    return QuoteLineItem._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      quoteId: quoteId,
      quote: quote,
      description: description,
      unit: unit,
      quantity: quantity,
      rate: rate,
      total: total);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QuoteLineItem &&
      id == other.id &&
      _quoteId == other._quoteId &&
      _quote == other._quote &&
      _description == other._description &&
      _unit == other._unit &&
      _quantity == other._quantity &&
      _rate == other._rate &&
      _total == other._total;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("QuoteLineItem {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("quoteId=" + "$_quoteId" + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("unit=" + "$_unit" + ", ");
    buffer.write("quantity=" + (_quantity != null ? _quantity!.toString() : "null") + ", ");
    buffer.write("rate=" + (_rate != null ? _rate!.toString() : "null") + ", ");
    buffer.write("total=" + (_total != null ? _total!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  QuoteLineItem copyWith({String? quoteId, Quote? quote, String? description, String? unit, double? quantity, double? rate, double? total}) {
    return QuoteLineItem._internal(
      id: id,
      quoteId: quoteId ?? this.quoteId,
      quote: quote ?? this.quote,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      total: total ?? this.total);
  }
  
  QuoteLineItem copyWithModelFieldValues({
    ModelFieldValue<String>? quoteId,
    ModelFieldValue<Quote?>? quote,
    ModelFieldValue<String>? description,
    ModelFieldValue<String?>? unit,
    ModelFieldValue<double>? quantity,
    ModelFieldValue<double>? rate,
    ModelFieldValue<double>? total
  }) {
    return QuoteLineItem._internal(
      id: id,
      quoteId: quoteId == null ? this.quoteId : quoteId.value,
      quote: quote == null ? this.quote : quote.value,
      description: description == null ? this.description : description.value,
      unit: unit == null ? this.unit : unit.value,
      quantity: quantity == null ? this.quantity : quantity.value,
      rate: rate == null ? this.rate : rate.value,
      total: total == null ? this.total : total.value
    );
  }
  
  QuoteLineItem.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _quoteId = json['quoteId'],
      _quote = json['quote'] != null
        ? Quote.fromJson(new Map<String, dynamic>.from(json['quote']['serializedData']))
        : null,
      _description = json['description'],
      _unit = json['unit'],
      _quantity = (json['quantity'] as num?)?.toDouble(),
      _rate = (json['rate'] as num?)?.toDouble(),
      _total = (json['total'] as num?)?.toDouble(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'quoteId': _quoteId, 'quote': _quote?.toJson(), 'description': _description, 'unit': _unit, 'quantity': _quantity, 'rate': _rate, 'total': _total, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'quoteId': _quoteId,
    'quote': _quote,
    'description': _description,
    'unit': _unit,
    'quantity': _quantity,
    'rate': _rate,
    'total': _total,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<QuoteLineItemModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<QuoteLineItemModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final QUOTEID = amplify_core.QueryField(fieldName: "quoteId");
  static final QUOTE = amplify_core.QueryField(
    fieldName: "quote",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Quote'));
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final UNIT = amplify_core.QueryField(fieldName: "unit");
  static final QUANTITY = amplify_core.QueryField(fieldName: "quantity");
  static final RATE = amplify_core.QueryField(fieldName: "rate");
  static final TOTAL = amplify_core.QueryField(fieldName: "total");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "QuoteLineItem";
    modelSchemaDefinition.pluralName = "QuoteLineItems";
    
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
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.QUOTEID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: QuoteLineItem.QUOTE,
      isRequired: false,
      targetNames: ["quoteId"],
      ofModelName: 'Quote'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.DESCRIPTION,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.UNIT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.QUANTITY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.RATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: QuoteLineItem.TOTAL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
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

class _QuoteLineItemModelType extends amplify_core.ModelType<QuoteLineItem> {
  const _QuoteLineItemModelType();
  
  @override
  QuoteLineItem fromJson(Map<String, dynamic> jsonData) {
    return QuoteLineItem.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'QuoteLineItem';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [QuoteLineItem] in your schema.
 */
class QuoteLineItemModelIdentifier implements amplify_core.ModelIdentifier<QuoteLineItem> {
  final String id;

  /** Create an instance of QuoteLineItemModelIdentifier using [id] the primary key. */
  const QuoteLineItemModelIdentifier({
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
  String toString() => 'QuoteLineItemModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is QuoteLineItemModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}
