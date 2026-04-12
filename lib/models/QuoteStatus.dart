// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously
import 'package:amplify_core/amplify_core.dart' as amplify_core;

enum QuoteStatus {
  Draft,
  Submitted,
  Accepted,
  Rejected
}

/** This is an auto generated class representing the QuoteStatus type in your schema. */
class QuoteStatusHelpers {
  static amplify_core.ModelFieldType getType() {
    return amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration);
  }
}
