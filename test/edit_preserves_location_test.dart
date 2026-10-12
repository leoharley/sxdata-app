import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sxdata/models/form_response.dart';
import 'package:sxdata/models/question.dart';
import 'package:sxdata/models/question_response.dart';
import 'package:sxdata/models/questionnaire.dart';
import 'package:sxdata/providers/form_provider.dart';

/// Edição de coleta: a localização é a da entrevista.
///
/// Ao editar, o app descartava as coordenadas originais e gravava a posição
/// do momento da correção. Coletas editadas no mesmo lugar terminavam todas
/// com a mesma coordenada, inviabilizando o KMZ do território.
void main() {
  const latitudeEntrevista = -10.7041;
  const longitudeEntrevista = -48.4172;

  Questionnaire questionario() => Questionnaire(
        id: 6,
        title: 'GERAL',
        description: '',
        createdBy: 1,
        status: 'active',
        requiresConsent: false,
        requiresLocation: true,
        requiresPhoto: false,
        version: '1',
        createdAt: DateTime(2026, 6, 16),
        updatedAt: DateTime(2026, 6, 16),
        questions: [
          Question(
            id: 10,
            questionnaireId: 6,
            questionText: 'Nome da propriedade',
            questionType: 'text',
            isRequired: false,
            orderIndex: 1,
          ),
        ],
      );

  FormResponse coletaOriginal() => FormResponse(
        id: 1727600000000,
        questionnaireId: 6,
        appliedBy: 17,
        consentGiven: true,
        clientId: 'c0ffee00-0000-4000-8000-000000000001',
        latitude: latitudeEntrevista,
        longitude: longitudeEntrevista,
        syncStatus: 'synced',
        startedAt: DateTime(2026, 9, 29, 9, 0, 12),
        completedAt: DateTime(2026, 9, 29, 9, 41, 5),
        responses: [QuestionResponse(questionId: 10, responseText: 'Fazenda Sta Rita')],
      );

  /// Reproduz o que as telas fazem ao abrir uma coleta para edição.
  FormProvider abrirParaEdicao(FormResponse coleta) {
    final q = questionario();
    final provider = FormProvider();
    provider.setEditMode(coleta.id.toString());
    provider.loadFormForEdit(coleta, q);
    return provider;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('abrir coleta para edição', () {
    test('mantém coordenadas, datas e client_id da entrevista', () {
      final original = coletaOriginal();
      final provider = abrirParaEdicao(original);

      final form = provider.currentForm!;
      expect(form.latitude, latitudeEntrevista);
      expect(form.longitude, longitudeEntrevista);
      expect(form.startedAt, original.startedAt);
      expect(form.completedAt, original.completedAt);
      expect(form.clientId, original.clientId);
    });

    test('startForm não recria o formulário já carregado', () {
      final original = coletaOriginal();
      final provider = abrirParaEdicao(original);
      final q = questionario();

      // Antes isto trocava o formulário por um vazio, sem coordenadas, e a
      // finalização capturava a posição de onde a edição estava sendo feita
      provider.startForm(q.id, 17, q.questions);

      expect(provider.currentForm!.latitude, latitudeEntrevista);
      expect(provider.currentForm!.startedAt, original.startedAt);
    });
  });

  group('captura de posição durante a edição', () {
    test('posição nova é ignorada', () {
      final provider = abrirParaEdicao(coletaOriginal());

      // Posição do escritório onde a coleta foi corrigida
      provider.setLocation(-15.7939, -47.8828, '');

      expect(provider.currentForm!.latitude, latitudeEntrevista);
      expect(provider.currentForm!.longitude, longitudeEntrevista);
    });

    test('várias coletas editadas no mesmo lugar mantêm cada uma a sua', () {
      final coordenadas = <List<double>>[
        [-10.7041, -48.4172],
        [-10.9123, -48.1007],
        [-11.2050, -48.6601],
      ];

      final resultados = coordenadas.map((c) {
        final coleta = coletaOriginal().copyWith(
          id: 1727600000000 + coordenadas.indexOf(c),
          latitude: c[0],
          longitude: c[1],
        );
        final provider = abrirParaEdicao(coleta);
        provider.setLocation(-15.7939, -47.8828, '');
        return [provider.currentForm!.latitude, provider.currentForm!.longitude];
      }).toList();

      expect(resultados, coordenadas);
    });

    test('"sem localização" não é marcado na edição', () {
      final provider = abrirParaEdicao(coletaOriginal());

      provider.markLocationUnavailable();

      expect(provider.currentForm!.locationName, isNull);
    });
  });

  test('fora da edição a posição capturada é gravada', () {
    final q = questionario();
    final provider = FormProvider();
    provider.startForm(q.id, 17, q.questions);

    provider.setLocation(-10.5, -48.2, '');

    expect(provider.currentForm!.latitude, -10.5);
    expect(provider.currentForm!.longitude, -48.2);
  });
}
