class QuestionOption {
  final int id;
  final String optionText;
  final String? optionValue;
  final int orderIndex;

  QuestionOption({
    required this.id,
    required this.optionText,
    this.optionValue,
    required this.orderIndex,
  });

  // Método auxiliar para converter string em int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty || value == 'null') return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    print('🔘 Parsing option: ${json['text']}');
    print('📋 Option JSON: $json');
    
    try {
      // Tratar o valor da opção - se estiver vazio, usar o texto
      String? optionValue = json['option_value']?.toString();
      if (optionValue != null && optionValue.trim().isEmpty) {
        optionValue = null; // Se for string vazia, usar null para usar o texto
      }

      final option = QuestionOption(
        id: _parseInt(json['id']),
        optionText: json['option_text']?.toString() ?? '',
        optionValue: optionValue,
        orderIndex: _parseInt(json['order_index']),
      );

      print('✅ Option parsed: ${option.optionText} (value: ${option.optionValue ?? 'using text'})');
      return option;
      
    } catch (e, stackTrace) {
      print('❌ Error in QuestionOption.fromJson: $e');
      print('📋 Stack trace: $stackTrace');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  // Método toJson() necessário para serialização
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': optionText,
      'value': optionValue,
      'order': orderIndex,
    };
  }

  @override
  String toString() {
    return 'QuestionOption{id: $id, text: $optionText, value: ${optionValue ?? "null"}}';
  }
}