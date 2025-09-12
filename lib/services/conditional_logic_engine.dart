import '../models/question.dart';
import '../models/conditional_logic.dart';

class ConditionalLogicEngine {
  /// Executa a lógica condicional para todas as questões e retorna os novos estados
  static Map<int, QuestionState> executeLogic(List<Question> questions, Map<int, dynamic> responses) {
    print('🎯 === EXECUTANDO LÓGICA CONDICIONAL ===');
    print('📝 Questões: ${questions.length}');
    print('📋 Respostas disponíveis: ${responses.length}');
    
    // Debug das respostas recebidas
    print('📋 === RESPOSTAS RECEBIDAS ===');
    responses.forEach((questionId, value) {
      print('📋 Questão ID $questionId: "$value" (${value.runtimeType})');
    });
    
    final Map<int, QuestionState> newStates = {};
    
    // Processar cada questão por índice
    for (int index = 0; index < questions.length; index++) {
      final question = questions[index];
      
      print('🔧 === PROCESSANDO QUESTÃO $index ===');
      print('🔧 ID: ${question.id}');
      print('🔧 Texto: "${question.questionText}"');
      print('🔧 Tem lógica: ${question.hasConditionalLogic}');
      
      // Estado inicial (padrão)
      bool visible = true;
      bool required = question.isRequired;
      
      // Aplicar lógica condicional se existir
      if (question.hasConditionalLogic) {
        final logic = question.parsedConditionalLogic!;
        print('🔧 Aplicando lógica condicional...');
        
        // Avaliar regras de visibilidade
        if (logic.visibility != null) {
          print('👁️ === AVALIANDO VISIBILIDADE ===');
          visible = _evaluateRule(logic.visibility!, responses, questions);
          print('👁️ Resultado visibilidade: $visible');
        }
        
        // Avaliar regras de obrigatoriedade (apenas se visível)
        if (visible && logic.required != null) {
          print('⚠️ === AVALIANDO OBRIGATORIEDADE ===');
          required = _evaluateRule(logic.required!, responses, questions);
          print('⚠️ Resultado obrigatoriedade: $required');
        } else if (!visible) {
          required = false; // Questão invisível não pode ser obrigatória
          print('⚠️ Questão invisível, required=false');
        }
      } else {
        print('ℹ️ Sem lógica condicional, usando valores padrão');
      }
      
      newStates[index] = QuestionState(
        visible: visible,
        required: required,
        originalRequired: question.isRequired,
      );
      
      print('✅ Estado final questão $index: visible=$visible, required=$required');
      print('');
    }
    
    print('🎯 === LÓGICA CONDICIONAL CONCLUÍDA ===');
    print('📊 Estados processados: ${newStates.length}');
    return newStates;
  }
  
  /// Avalia uma regra condicional específica
  static bool _evaluateRule(ConditionalRule rule, Map<int, dynamic> responses, List<Question> questions) {
    print('🔍 === AVALIANDO REGRA ===');
    print('🔍 Operador: ${rule.operator}');
    print('🔍 Condições: ${rule.conditions.length}');
    
    if (rule.conditions.isEmpty) {
      print('⚠️ Regra sem condições, retornando true');
      return true;
    }
    
    final List<bool> results = [];
    
    for (int i = 0; i < rule.conditions.length; i++) {
      final condition = rule.conditions[i];
      print('🔍 --- Condição $i ---');
      print('🔍 Questão ID: ${condition.questionId}');
      print('🔍 Operador: ${condition.operator}');
      print('🔍 Valor esperado: "${condition.value}"');
      
      // Obter resposta da questão referenciada
      final response = responses[condition.questionId];
      print('📝 Resposta encontrada: "$response" (${response.runtimeType})');
      
      // Avaliar condição
      final conditionResult = _evaluateCondition(condition, response);
      print('🔍 Resultado da condição $i: $conditionResult');
      
      results.add(conditionResult);
    }
    
    // Aplicar operador lógico
    bool finalResult;
    if (rule.operator.toUpperCase() == 'OR') {
      finalResult = results.any((result) => result);
      print('🔍 Operador OR: [${results.join(', ')}] = $finalResult');
    } else {
      // Default: AND
      finalResult = results.every((result) => result);
      print('🔍 Operador AND: [${results.join(', ')}] = $finalResult');
    }
    
    print('🔍 === FIM AVALIAÇÃO REGRA: $finalResult ===');
    return finalResult;
  }
  
  /// Avalia uma condição específica
  static bool _evaluateCondition(ConditionalCondition condition, dynamic response) {
    print('🔍 Avaliando condição detalhada:');
    print('   - Resposta: "$response" (tipo: ${response.runtimeType})');
    print('   - Operador: ${condition.operator}');
    print('   - Valor esperado: "${condition.value}" (tipo: ${condition.value.runtimeType})');
    
    // Se não há resposta, alguns operadores podem ainda ser verdadeiros
    if (response == null) {
      final result = condition.operator == 'not_equals' || 
                    condition.operator == 'not_contains' ||
                    condition.operator == 'is_empty';
      print('🔍 Resposta NULL, resultado para ${condition.operator}: $result');
      return result;
    }

    bool result = false;
    switch (condition.operator.toLowerCase()) {
      case 'equals':
        result = _compareEquals(response, condition.value);
        break;
      
      case 'not_equals':
        result = !_compareEquals(response, condition.value);
        break;
      
      case 'contains':
        result = _compareContains(response, condition.value);
        break;
      
      case 'not_contains':
        result = !_compareContains(response, condition.value);
        break;
      
      case 'greater_than':
        result = _compareGreaterThan(response, condition.value);
        break;
      
      case 'less_than':
        result = _compareLessThan(response, condition.value);
        break;
      
      case 'greater_than_or_equal':
        result = _compareGreaterThanOrEqual(response, condition.value);
        break;
      
      case 'less_than_or_equal':
        result = _compareLessThanOrEqual(response, condition.value);
        break;
      
      case 'is_empty':
        result = _isEmpty(response);
        break;
      
      case 'is_not_empty':
        result = !_isEmpty(response);
        break;
      
      default:
        print('⚠️ Operador não reconhecido: ${condition.operator}');
        result = false;
    }
    
    print('🔍 Resultado final da condição: $result');
    return result;
  }
  
  // Métodos de comparação melhorados
  static bool _compareEquals(dynamic response, dynamic value) {
    if (response is List) {
      // Para checkbox, verificar se lista contém o valor
      final result = response.any((item) => 
        item?.toString().toLowerCase().trim() == value?.toString().toLowerCase().trim());
      print('🔍 Lista contém "${value}": $result (lista: $response)');
      return result;
    }
    
    // Comparação padrão (case-insensitive e trim)
    final responseStr = response?.toString().toLowerCase().trim() ?? '';
    final valueStr = value?.toString().toLowerCase().trim() ?? '';
    final result = responseStr == valueStr;
    print('🔍 "$responseStr" equals "$valueStr": $result');
    return result;
  }

  static bool _compareContains(dynamic response, dynamic value) {
    if (response is List) {
      final result = response.any((item) => 
        item?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') == true);
      print('🔍 Lista contém substring "${value}": $result');
      return result;
    }
    
    final result = response?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') == true;
    print('🔍 "${response}" contém "${value}": $result');
    return result;
  }

  static bool _compareGreaterThan(dynamic response, dynamic value) {
    final responseNum = _parseNumber(response);
    final valueNum = _parseNumber(value);
    
    if (responseNum == null || valueNum == null) {
      print('🔍 Não foi possível converter para números: response=$response, value=$value');
      return false;
    }
    
    final result = responseNum > valueNum;
    print('🔍 $responseNum > $valueNum: $result');
    return result;
  }

  static bool _compareLessThan(dynamic response, dynamic value) {
    final responseNum = _parseNumber(response);
    final valueNum = _parseNumber(value);
    
    if (responseNum == null || valueNum == null) {
      print('🔍 Não foi possível converter para números: response=$response, value=$value');
      return false;
    }
    
    final result = responseNum < valueNum;
    print('🔍 $responseNum < $valueNum: $result');
    return result;
  }

  static bool _compareGreaterThanOrEqual(dynamic response, dynamic value) {
    final responseNum = _parseNumber(response);
    final valueNum = _parseNumber(value);
    
    if (responseNum == null || valueNum == null) {
      print('🔍 Não foi possível converter para números: response=$response, value=$value');
      return false;
    }
    
    final result = responseNum >= valueNum;
    print('🔍 $responseNum >= $valueNum: $result');
    return result;
  }

  static bool _compareLessThanOrEqual(dynamic response, dynamic value) {
    final responseNum = _parseNumber(response);
    final valueNum = _parseNumber(value);
    
    if (responseNum == null || valueNum == null) {
      print('🔍 Não foi possível converter para números: response=$response, value=$value');
      return false;
    }
    
    final result = responseNum <= valueNum;
    print('🔍 $responseNum <= $valueNum: $result');
    return result;
  }

  static bool _isEmpty(dynamic response) {
    if (response == null) return true;
    if (response is String) return response.trim().isEmpty;
    if (response is List) return response.isEmpty;
    return false;
  }

  static double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Valida todas as respostas considerando lógica condicional
  static ValidationResult validateResponses(List<Question> questions, Map<int, dynamic> responses) {
    print('✅ === VALIDANDO RESPOSTAS COM LÓGICA CONDICIONAL ===');
    
    final List<String> errors = [];
    final List<String> warnings = [];
    
    // Executar lógica condicional para obter estados atuais
    final states = executeLogic(questions, responses);
    
    // Validar cada questão visível e obrigatória
    for (int index = 0; index < questions.length; index++) {
      final question = questions[index];
      final state = states[index]!;
      
      // Pular questões não visíveis
      if (!state.visible) {
        print('ℹ️ Pulando validação da questão ${question.id} (não visível)');
        continue;
      }
      
      // Verificar se questão obrigatória foi respondida
      if (state.required) {
        final response = responses[question.id];
        
        if (_isResponseEmpty(response, question.questionType)) {
          errors.add('A questão "${question.questionText}" é obrigatória e deve ser respondida');
          print('❌ Questão obrigatória ${question.id} não respondida');
        } else {
          print('✅ Questão obrigatória ${question.id} respondida');
        }
      }
    }
    
    print('✅ Validação concluída: ${errors.length} erros, ${warnings.length} avisos');
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Verifica se uma resposta está vazia baseada no tipo da questão
  static bool _isResponseEmpty(dynamic response, String questionType) {
    if (response == null) return true;
    
    switch (questionType.toLowerCase()) {
      case 'text':
      case 'textarea':
      case 'email':
        return response is! String || response.trim().isEmpty;
      
      case 'number':
        return response is! num && (response is! String || double.tryParse(response) == null);
      
      case 'date':
      case 'datetime':
        return response is! DateTime && (response is! String || DateTime.tryParse(response) == null);
      
      case 'radio':
        return response is! String || response.isEmpty;
      
      case 'checkbox':
        return response is! List || response.isEmpty;
      
      case 'select':
        return response is! String || response.isEmpty;
      
      default:
        return response.toString().trim().isEmpty;
    }
  }
}