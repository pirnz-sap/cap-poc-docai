namespace com.sap.docai;

using { managed, cuid } from '@sap/cds/common';

entity ProcessingBatches : cuid, managed {
  fileName: String(255);
  fileType: String(10); // 'eml' or 'pdf'
  uploadedAt: Timestamp;
  status: String(20); // 'uploaded', 'extracted', 'processing', 'completed', 'failed'
  totalDocuments: Integer default 0;
  processedDocuments: Integer default 0;
  schemaId: String(255); // DocAI schema version ID
  documents: Composition of many Documents on documents.batch = $self;
}

entity Documents : cuid, managed {
  batch: Association to ProcessingBatches;
  fileName: String(255);
  fileContent: LargeBinary;
  mimeType: String(100);
  uploadedAt: Timestamp;
  status: String(20); // 'pending', 'processing', 'extracted', 'validated', 'failed'
  docaiDocumentId: String(255);
  extractionStatus: String(50);
  extractionError: String(5000);
  extractionData: LargeString; // Schema-agnostic JSON extraction (all fields, groups, tables)
  extractionSource: String(20); // 'callback' or 'api'
  schemaVersionId: String(255); // Schema version ID from DocAI
  clientId: String(255); // Client ID from DocAI
  validationResults: Composition of many ValidationResults on validationResults.document = $self;
}

entity ValidationResults : cuid {
  document: Association to Documents;
  fieldName: String(50);
  isValid: Boolean;
  isMandatory: Boolean;
  value: String(5000);
  confidence: Decimal(5,4);
  errorMessage: String(5000);
  validatedAt: Timestamp;
}

// Audit Metrics - Detailed document extraction metrics
entity AuditMetrics : cuid {
  snapshotAt: Timestamp;
  docaiDocumentId: String(255) @assert.unique;
  clientId: String(255);
  schemaVersionId: String(255);
  schemaName: String(255);
  schemaVersion: Integer;
  documentCreatedAt: Timestamp;
  documentFinishedAt: Timestamp;
  extractionDuration: Integer; // milliseconds
  status: String(50);
  documentConfidence: Decimal(5,4);
  avgFieldConfidence: Decimal(5,4);
  totalFields: Integer;
  confirmedFields: Integer;
  rawDocumentData: LargeString; // JSON snapshot of document data
}

// Client Schema Usage - Aggregated summary metrics
entity ClientSchemaUsage : cuid {
  clientId: String(255);
  schemaVersionId: String(255);
  schemaName: String(255);
  schemaVersion: Integer;
  totalExtractions: Integer default 0;
  lastExtractionAt: Timestamp;
  avgConfidence: Decimal(5,4);
  avgDuration: Integer; // milliseconds
  snapshotAt: Timestamp;
}

// Filter Value Lists for Audit Dashboard
entity MailProcessingStatus : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

entity ResponsibilityRegion : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

entity PartnerProfile : cuid {
  key code: String(100);
  name: String(255);
  description: String(500);
}

entity AttachmentProcessingStatus : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

entity AttachmentExtractionStatus : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

entity DocumentType : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

entity BasicRoutingStatus : cuid {
  key code: String(50);
  name: String(100);
  description: String(500);
}

// Field Extraction Metrics - Per-field performance metrics
entity FieldExtractionMetrics : cuid {
  clientId: String(255);
  schemaVersionId: String(255);
  schemaName: String(255);
  schemaVersion: Integer;
  fieldName: String(255);        // Entity name from SchemaEntities
  fieldType: String(50);          // 'Field', 'Table', 'Group'
  fieldDataType: String(50);      // 'String', 'Number', 'Date'

  // Aggregated metrics
  totalExtractions: Integer default 0;
  avgConfidence: Decimal(5,4);
  minConfidence: Decimal(5,4);
  maxConfidence: Decimal(5,4);
  belowThresholdCount: Integer default 0;  // confidence < 0.8

  // Metadata
  snapshotAt: Timestamp;
  lastExtractionAt: Timestamp;
}

// Schema Version Snapshot - Schema version metadata and field definitions
entity SchemaVersionSnapshot : cuid {
  schemaVersionId: String(255) @assert.unique;
  schemaId: String(255);
  schemaName: String(255);
  version: Integer;
  clientId: String(255);

  // Timing
  createdAt: Timestamp;
  deployedAt: Timestamp;
  isActive: Boolean default false;

  // Schema definition
  description: String(500);
  processingInstructions: String(1000);

  // Field definitions (JSON)
  fieldDefinitions: LargeString;  // JSON array of SchemaEntities

  // Usage metrics
  totalDocumentsProcessed: Integer default 0;
  snapshotAt: Timestamp;
}

// Schema Version Changes - Track changes between schema versions
entity SchemaVersionChanges : cuid {
  schemaId: String(255);
  schemaName: String(255);
  clientId: String(255);

  // Version transition
  versionFrom: Integer;
  versionTo: Integer;
  schemaVersionIdFrom: String(255);
  schemaVersionIdTo: String(255);

  // Change details
  changeType: String(50);         // 'FIELD_ADDED', 'FIELD_REMOVED', 'FIELD_MODIFIED', 'SCHEMA_CREATED'
  fieldName: String(255);
  fieldType: String(50);

  // Change specifics (JSON)
  changeDetails: LargeString;     // JSON with before/after field definitions

  // Metadata
  detectedAt: Timestamp;
}
