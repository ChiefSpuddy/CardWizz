import 'package:cloud_kit/cloud_kit.dart';
import '../models/tcg_card.dart';

class CloudSyncService {
  final CloudKit _cloudKit;
  final String _containerIdentifier = 'iCloud.com.cardwizz.app';
  final String _zoneName = 'CardCollection';
  
  CloudSyncService() : _cloudKit = CloudKit(containerIdentifier: 'iCloud.com.cardwizz.app');

  Future<void> initialize() async {
    try {
      await _cloudKit.configure();
      await _setupCustomZone();
      print('CloudKit initialized successfully');
    } catch (e) {
      print('Error initializing CloudKit: $e');
      rethrow;
    }
  }

  Future<void> _setupCustomZone() async {
    try {
      await _cloudKit.privateCloudDatabase.saveZone(
        CKRecordZone(zoneName: _zoneName),
      );
    } catch (e) {
      print('Error creating zone: $e');
      // Ignore if zone already exists
    }
  }

  Future<void> syncCards(List<TcgCard> cards) async {
    try {
      final operations = cards.map((card) {
        final record = CKRecord(
          recordType: 'Card',
          recordID: CKRecordID(
            recordName: card.id,
            zoneName: _zoneName,
          ),
        );

        record.setData({
          'data': card.toJson(),
          'lastModified': DateTime.now().toIso8601String(),
        });

        return record;
      }).toList();

      await _cloudKit.privateCloudDatabase.saveRecords(operations);
      print('Synced ${cards.length} cards to iCloud');
    } catch (e) {
      print('Error syncing to iCloud: $e');
      rethrow;
    }
  }

  Future<List<TcgCard>> fetchCards() async {
    try {
      final query = CKQuery(
        recordType: 'Card',
        zoneName: _zoneName,
        filterPredicate: null, // Fetch all cards
      );

      final records = await _cloudKit.privateCloudDatabase.performQuery(query);
      
      return records.map((record) {
        final data = record.data['data'] as Map<String, dynamic>;
        return TcgCard.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching from iCloud: $e');
      return [];
    }
  }

  Stream<List<CKRecord>> watchCloudChanges() {
    return _cloudKit.privateCloudDatabase.watchChanges(
      zoneName: _zoneName,
      changeToken: null, // Start from current
    );
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final record = await _cloudKit.privateCloudDatabase.fetchRecord(
        CKRecordID(
          recordName: 'last_sync',
          zoneName: _zoneName,
        ),
      );
      
      final timestamp = record?.data['timestamp'] as String?;
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLastSyncTime(DateTime timestamp) async {
    final record = CKRecord(
      recordType: 'SyncMetadata',
      recordID: CKRecordID(
        recordName: 'last_sync',
        zoneName: _zoneName,
      ),
    );

    record.setData({
      'timestamp': timestamp.toIso8601String(),
    });

    await _cloudKit.privateCloudDatabase.saveRecord(record);
  }
}
