/*
 * Package : sbom
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 25/09/2021
 * Copyright :  S.Hamblett
 */
import 'package:sbom/sbom.dart';
import 'package:test/test.dart';

@TestOn('VM')
void main() {
  group('Document creation section', () {
    test('Valid file', () {
      final config = SbomConfiguration(
          ['-p', 'test/sbom/spdx/generation/documentcreation/configuration']);
      config.parseConfigurationFile();
      expect(config.valid, isTrue);
      expect(config.outputType, SbomType.spdx);
      final generator = SbomGenerator(config);
      generator.generate();
      expect(generator.valid, isTrue);
      expect(generator.tags.tags.length, 11);
      expect(generator.tags.tagByName('SPDXVersion').values[0], 'SPDX-2.2');
      expect(generator.tags.tagByName('DataLicense').values[0], 'CC0-1.0');
      expect(generator.tags.tagByName('SPDXID').values[0],
          'SPDX Identifier from configuration');
      expect(generator.tags.tagByName('DocumentName').values[0],
          'Document name from configuration');
      expect(generator.tags.tagByName('DocumentNamespace').values[0],
          'Document name space from configuration');
      expect(generator.tags.tagByName('ExternalDocumentRef').values.length, 2);
      expect(generator.tags.tagByName('ExternalDocumentRef').values[0],
          'External Doc Ref 1');
      expect(generator.tags.tagByName('ExternalDocumentRef').values[1],
          'External Doc Ref 2');
      expect(generator.tags.tagByName('LicenseListVersion').values[0], '3.8');
      expect(generator.tags.tagByName('Creator').values[0], 'SJH');
      expect(generator.tags.tagByName('Created').values[0],
          '2021-10-12T14:00:00Z');
      expect(generator.tags.tagByName('CreatorComment').values[0],
          'Creator comment from configuration');
      expect(generator.tags.tagByName('DocumentComment').values[0],
          'Document comment from configuration');
      expect(generator.tags.sectionValid('documentCreation').isEmpty, isTrue);
    });
  });
}
