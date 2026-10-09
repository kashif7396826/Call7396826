import '../../core/network/api_client.dart';
import 'campaign.dart';

class CampaignRepository {
  final _api = ApiClient.instance;

  Future<List<Campaign>> list() async {
    final response = await _api.get('/campaigns');
    final data = (response.data as Map<String, dynamic>)['campaigns'] as List;
    return data.map((c) => Campaign.fromJson(c as Map<String, dynamic>)).toList();
  }
}
