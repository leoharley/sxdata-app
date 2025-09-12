import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/questionnaire.dart';
import '../models/form_response.dart';

class LocalStorageService {
  static const String _questionnairesKey = 'questionnaires';
  static const String _formsKey = 'form_responses';

  // Questionnaires
  static Future<void> saveQuestionnaires(List<Questionnaire> questionnaires) async {
    try {
      print('💾 Salvando ${questionnaires.length} questionários');
      final prefs = await SharedPreferences.getInstance();
      final jsonList = questionnaires.map((q) => q.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_questionnairesKey, jsonString);
      print('✅ Questionários salvos com sucesso');
    } catch (e, stackTrace) {
      print('❌ Erro ao salvar questionários: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Questionnaire>> getQuestionnaires() async {
    try {
      print('📖 Carregando questionários do storage local');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_questionnairesKey);
      
      if (jsonString == null) {
        print('⚠️ Nenhum questionário encontrado no storage local');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final questionnaires = jsonList
          .map((json) => Questionnaire.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ ${questionnaires.length} questionários carregados do storage local');
      return questionnaires;
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar questionários do storage local: $e');
      print('📋 Stack trace: $stackTrace');
      return [];
    }
  }

  // Form Responses - VERSÃO CORRIGIDA
  static Future<void> saveFormResponse(FormResponse form) async {
    try {
      print('💾 === INICIANDO SALVAMENTO DE FORMULÁRIO ===');
      print('📋 QuestionÃ¡rio ID: ${form.questionnaireId}');
      print('📋 Aplicado por: ${form.appliedBy}');
      print('📋 Respostas: ${form.responses.length}');
      print('📋 Status de sincronização: ${form.syncStatus}');
      print('📋 ID do formulário: ${form.id}');
      
      // Verificar se SharedPreferences está funcionando
      final prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences obtido com sucesso');
      
      // Gerar um ID único se não tiver
      final formWithId = form.id == null 
          ? form.copyWith(id: DateTime.now().millisecondsSinceEpoch)
          : form;
      
      print('📋 Formulário com ID: ${formWithId.id}');
      
      // Carregar formas existentes
      print('📖 Carregando formulários existentes...');
      List<FormResponse> existingForms = [];
      
      try {
        final existingJsonString = prefs.getString(_formsKey);
        print('📋 JSON existente encontrado: ${existingJsonString != null}');
        
        if (existingJsonString != null) {
          final existingJsonList = jsonDecode(existingJsonString) as List<dynamic>;
          existingForms = existingJsonList
              .map((json) => FormResponse.fromJson(json as Map<String, dynamic>))
              .toList();
          print('✅ ${existingForms.length} formulários existentes carregados');
        } else {
          print('📋 Nenhum formulário existente encontrado - criando nova lista');
        }
      } catch (e) {
        print('⚠️ Erro ao carregar formulários existentes: $e - começando com lista vazia');
        existingForms = [];
      }
      
      // Verificar se já existe um formulário com o mesmo ID
      bool formExists = false;
      for (int i = 0; i < existingForms.length; i++) {
        if (existingForms[i].id == formWithId.id) {
          print('🔄 Atualizando formulário existente com ID: ${formWithId.id}');
          existingForms[i] = formWithId;
          formExists = true;
          break;
        }
      }
      
      // Se não existe, adicionar à lista
      if (!formExists) {
        print('➕ Adicionando novo formulário à lista');
        existingForms.add(formWithId);
      }
      
      print('📋 Total de formulários para salvar: ${existingForms.length}');
      
      // Serializar todos os formulários
      print('🔄 Serializando formulários...');
      final jsonList = <Map<String, dynamic>>[];
      for (int i = 0; i < existingForms.length; i++) {
        try {
          final json = existingForms[i].toJson();
          jsonList.add(json);
          print('✅ Formulário $i serializado (ID: ${existingForms[i].id})');
        } catch (e) {
          print('❌ Erro ao serializar formulário $i: $e');
          // Continua com os outros formulários
        }
      }
      
      // Converter para string JSON
      print('🔄 Convertendo para JSON string...');
      final jsonString = jsonEncode(jsonList);
      print('📋 Tamanho do JSON: ${jsonString.length} caracteres');
      
      // Salvar no SharedPreferences
      print('💾 Salvando no SharedPreferences...');
      final saveResult = await prefs.setString(_formsKey, jsonString);
      print('📋 Resultado do salvamento: $saveResult');
      
      if (saveResult) {
        print('✅ === FORMULÁRIO SALVO COM SUCESSO ===');
        print('📋 ID salvo: ${formWithId.id}');
        print('📋 Total de formulários no storage: ${existingForms.length}');
        
        // Verificação imediata para confirmar salvamento
        final verification = prefs.getString(_formsKey);
        if (verification != null) {
          final verificationList = jsonDecode(verification) as List<dynamic>;
          print('✅ Verificação: ${verificationList.length} formulários confirmados no storage');
        } else {
          print('❌ ERRO: Verificação falhou - nada encontrado no storage após salvamento');
        }
      } else {
        print('❌ ERRO: SharedPreferences.setString retornou false');
        throw Exception('Falha ao salvar no SharedPreferences');
      }
      
    } catch (e, stackTrace) {
      print('❌ === ERRO DURANTE SALVAMENTO ===');
      print('❌ Erro: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<FormResponse>> getFormResponses() async {
    try {
      print('📖 === CARREGANDO FORMULÁRIOS DO STORAGE ===');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_formsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('⚠️ Nenhuma resposta encontrada no storage local');
        return [];
      }
      
      print('📋 JSON encontrado com ${jsonString.length} caracteres');
      
      try {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        print('📋 Lista JSON decodificada com ${jsonList.length} itens');
        
        final forms = <FormResponse>[];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final form = FormResponse.fromJson(jsonList[i] as Map<String, dynamic>);
            forms.add(form);
            print('✅ Formulário $i carregado (ID: ${form.id}, Status: ${form.syncStatus})');
          } catch (e) {
            print('❌ Erro ao carregar formulário $i: $e');
            // Continua com os outros
          }
        }
        
        print('✅ === ${forms.length} FORMULÁRIOS CARREGADOS COM SUCESSO ===');
        return forms;
        
      } catch (e) {
        print('❌ Erro ao decodificar JSON: $e');
        print('📋 JSON problemático (primeiros 200 chars): ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
        return [];
      }
      
    } catch (e, stackTrace) {
      print('❌ === ERRO DURANTE CARREGAMENTO ===');
      print('❌ Erro: $e');
      print('📋 Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<void> updateFormSyncStatus(int formId, String status) async {
    try {
      print('🔄 === ATUALIZANDO STATUS DE SINCRONIZAÇÃO ===');
      print('📋 Form ID: $formId');
      print('📋 Novo status: $status');
      
      List<FormResponse> forms = await getFormResponses();
      print('📋 ${forms.length} formulários carregados para atualização');
      
      bool formFound = false;
      for (int i = 0; i < forms.length; i++) {
        if (forms[i].id == formId) {
          print('✅ Formulário encontrado na posição $i');
          forms[i] = forms[i].copyWith(syncStatus: status);
          formFound = true;
          break;
        }
      }
      
      if (!formFound) {
        print('❌ Formulário com ID $formId não encontrado');
        throw Exception('Formulário não encontrado');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = forms.map((f) => f.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final result = await prefs.setString(_formsKey, jsonString);
      
      if (result) {
        print('✅ === STATUS ATUALIZADO COM SUCESSO ===');
      } else {
        print('❌ Falha ao salvar status atualizado');
        throw Exception('Falha ao salvar');
      }
      
    } catch (e, stackTrace) {
      print('❌ === ERRO DURANTE ATUALIZAÇÃO DE STATUS ===');
      print('❌ Erro: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Métodos utilitários
  static Future<void> clearQuestionnaires() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_questionnairesKey);
      print('🧹 Questionários limpos do storage local');
    } catch (e) {
      print('❌ Erro ao limpar questionários: $e');
    }
  }

  static Future<void> clearFormResponses() async {
    try {
      print('🧹 === LIMPANDO FORMULÁRIOS DO STORAGE ===');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_formsKey);
      print('📋 Resultado da limpeza: $result');
      
      // Verificar se realmente foi limpo
      final verification = prefs.getString(_formsKey);
      if (verification == null) {
        print('✅ Formulários limpos com sucesso');
      } else {
        print('❌ Erro: ainda há dados após limpeza');
      }
    } catch (e) {
      print('❌ Erro ao limpar respostas: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await clearQuestionnaires();
      await clearFormResponses();
      print('🧹 Todo o storage local limpo');
    } catch (e) {
      print('❌ Erro ao limpar storage: $e');
    }
  }

  // Debug melhorado
  static Future<void> debugPrintStorage() async {
    try {
      print('🔍 === DEBUG STORAGE DETALHADO ===');
      
      // Debug dos questionários
      final questionnaires = await getQuestionnaires();
      print('📋 Questionários: ${questionnaires.length}');
      for (var q in questionnaires) {
        print('   - ${q.title} (ID: ${q.id}, ${q.questions.length} questões)');
      }
      
      // Debug dos formulários  
      final forms = await getFormResponses();
      print('📝 Formulários: ${forms.length}');
      for (var f in forms) {
        print('   - ID: ${f.id}, Questionário: ${f.questionnaireId}, Status: ${f.syncStatus}, Respostas: ${f.responses.length}');
        print('     Iniciado: ${f.startedAt}');
        print('     Concluído: ${f.completedAt}');
        print('     Aplicador: ${f.appliedBy}');
        if (f.latitude != null && f.longitude != null) {
          print('     Localização: ${f.latitude}, ${f.longitude}');
        }
        if (f.photoPath != null) {
          print('     Foto: ${f.photoPath}');
        }
      }
      
      // Debug do SharedPreferences diretamente
      final prefs = await SharedPreferences.getInstance();
      final rawFormsData = prefs.getString(_formsKey);
      print('📋 Dados brutos no SharedPreferences:');
      print('   - Chave $_formsKey existe: ${rawFormsData != null}');
      if (rawFormsData != null) {
        print('   - Tamanho: ${rawFormsData.length} caracteres');
        print('   - Primeiros 100 chars: ${rawFormsData.substring(0, rawFormsData.length > 100 ? 100 : rawFormsData.length)}');
      }
      
      // Listar todas as chaves do SharedPreferences
      final allKeys = prefs.getKeys();
      print('📋 Todas as chaves no SharedPreferences: $allKeys');
      
      print('🔍 === FIM DEBUG DETALHADO ===');
    } catch (e) {
      print('❌ Erro no debug do storage: $e');
    }
  }

  // Método para testar salvamento
  static Future<bool> testSaveFormResponse() async {
    try {
      print('🧪 === TESTE DE SALVAMENTO ===');
      
      // Criar um formulário de teste
      final testForm = FormResponse(
        id: 999999,
        questionnaireId: 1,
        appliedBy: 1,
        consentGiven: true,
        syncStatus: 'test',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        responses: [],
      );
      
      print('📋 Salvando formulário de teste...');
      await saveFormResponse(testForm);
      
      print('📋 Verificando se foi salvo...');
      final forms = await getFormResponses();
      final testFormFound = forms.any((f) => f.id == 999999);
      
      if (testFormFound) {
        print('✅ Teste PASSOU: formulário salvo e recuperado com sucesso');
        
        // Limpar o teste
        final filteredForms = forms.where((f) => f.id != 999999).toList();
        final prefs = await SharedPreferences.getInstance();
        if (filteredForms.isEmpty) {
          await prefs.remove(_formsKey);
        } else {
          final jsonList = filteredForms.map((f) => f.toJson()).toList();
          final jsonString = jsonEncode(jsonList);
          await prefs.setString(_formsKey, jsonString);
        }
        print('🧹 Formulário de teste removido');
        
        return true;
      } else {
        print('❌ Teste FALHOU: formulário não foi encontrado após salvamento');
        return false;
      }
      
    } catch (e) {
      print('❌ Teste FALHOU com erro: $e');
      return false;
    }
  }
}