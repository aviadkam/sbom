/*
 * Package : sbom
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2021
 * Copyright :  S.Hamblett
 */

part of sbom;

/// The SBOM SPDX output generator class.
class SbomSpdxOutputGenerator extends SbomIOutputGenerator {
  /// Construction
  SbomSpdxOutputGenerator(this.configuration);

  /// SBOM configuration.
  final SbomConfiguration configuration;

  /// Update a tags value from a list.
  void _updateTagListValue(YamlMap section, String key) {
    for (final val in section[key]) {
      tags.tagByName(key).value = val;
    }
  }

  /// Build the document creation section.
  bool _buildDocumentCreation() {
    SbomUtilities.louder('Building SPDX Document Creation section');
    // If we have a document creation section in the SBOM configuration process it
    if (configuration.sbomConfigurationContents[SbomConstants.sbomSpdx]
        .containsKey(SbomSpdxSectionNames.documentCreation)) {
      final section =
          configuration.sbomConfigurationContents[SbomConstants.sbomSpdx]
              [SbomSpdxSectionNames.documentCreation];
      // Process each tag found in the section
      for (final key in section.keys) {
        if (tags.exists(key)) {
          // If the tag value is set by the tag builder it cannot be overridden by the configuration
          // unless this option is specified
          if (!tags.tagByName(key).canBeOverridden) {
            SbomUtilities.warning(
                'SPDX tag $key cannot be overridden by configuration');
          } else {
            // Update the tag value from configuration, checking for list values
            if (section[key] is YamlList) {
              _updateTagListValue(section, key);
            } else {
              tags.tagByName(key).value = section[key];
            }
          }
        } else {
          SbomUtilities.warning(
              'SPDX document creation tag $key is not a valid SPDX tag name - not processing');
        }
      }
    }
    // Generate the environment tags
    // Document name and namespace, only if we have a package name
    if (configuration.packageName != SbomConstants.defaultPackageName) {
      tags.tagByName(SbomSpdxTagNames.documentName).value =
          configuration.packageName;
      tags.tagByName(SbomSpdxTagNames.documentNamespace).value =
          '${SbomConstants.pubUrl}${configuration.packageName}';
    }

    return true;
  }

  /// Build
  @override
  bool build() {
    SbomUtilities.loud('Building SPDX sections');
    if (!configuration.sbomConfigurationContents
        .containsKey(SbomConstants.sbomSpdx)) {
      SbomUtilities.error(
          'Cannot build SPDX sections, no spdx tag in SBOM configuration file');
      return false;
    }
    // Build the tag list
    tags = SbomSpdxTags(SbomSpdxTagBuilder());
    bool result = _buildDocumentCreation();
    if (!result) {
      SbomUtilities.error('Failed to build SPDX Document Creation section.');
      return false;
    }
    return true;
  }

  /// Validate the document creation section.
  /// True indicates validation succeeded.
  bool _validateDocumentCreation() {
    final result = tags.sectionValid(SbomSpdxSectionNames.documentCreation);
    if (result.isNotEmpty) {
      SbomUtilities.error(
          'Failed to validate SPDX Document Creation section, failed tags are ${SbomUtilities.tagsToString(result)}');
      return false;
    }
    // Check for any potential specification violations, only warn these.
    // Document creator
    final tag = tags.tagByName(SbomSpdxTagNames.creator);
    for (final value in tag.values) {
      if (!value.contains(SbomSpdxConstants.creatorTool) &&
          !value.contains(SbomSpdxConstants.creatorPerson) &&
          !value.contains(SbomSpdxConstants.creatorOrganisation)) {
        SbomUtilities.warning(
            'SPDX document creation section has invalid creator tag values - "$value"');
      }
    }
    return true;
  }

  /// Validate
  @override
  bool validate() {
    SbomUtilities.loud('Validating SPDX sections');
    SbomUtilities.louder('Validating SPDX Document Creation section');
    final result = _validateDocumentCreation();
    if (!result) {
      return false;
    }
    return true;
  }

  /// Generate the document creation section.
  bool _generateDocumentCreation(File outputFile) {
    try {
      final sectionTags =
          tags.sectionTags(SbomSpdxSectionNames.documentCreation);
      for (final tag in sectionTags) {
        if (tag.isSet()) {
          for (final value in tag.values) {
            final str =
                '${tag.name}${SbomSpdxConstants.spdxTagValueSeparator}$value\r';
            outputFile.writeAsStringSync(str, mode: FileMode.append);
          }
        }
      }
    } on FileSystemException {
      return false;
    }
    return true;
  }

  /// Generate
  @override
  bool generate() {
    SbomUtilities.loud('Generating SPDX SBOM');
    // Create the sbom output file
    final outputFileName = path.join(
        configuration.packageTopLevel, SbomSpdxConstants.outputFileName);
    final outputFile = File(outputFileName);
    if (outputFile.existsSync()) {
      try {
        outputFile.deleteSync();
      } on Exception {
        SbomUtilities.error(
            'SPDX SBOM generation - unable to delete existing sbom file at $outputFileName - aborting generation');
        return false;
      }
    }
    try {
      outputFile.createSync();
    } on FileSystemException {
      SbomUtilities.error(
          'SPDX SBOM generation - unable to create output sbom file at $outputFileName - aborting generation');
      return false;
    }
    SbomUtilities.louder('Generating SPDX Document Creation section');
    var result = _generateDocumentCreation(outputFile);
    if (!result) {
      SbomUtilities.error(
          'SPDX SBOM generation - unable to generate ethe document creation section in file at $outputFileName - aborting generation');
      return false;
    }
    sbomFilePath = outputFileName;

    return true;
  }
}
