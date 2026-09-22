import '../../core/network/api_client.dart';
import 'contact.dart';

class ContactRepository {
  final _api = ApiClient.instance;

  Future<List<Contact>> list({String? search, String? stage, int page = 1, int limit = 25}) async {
    final response = await _api.get('/contacts', query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'q': search,
      if (stage != null) 'stage': stage,
    });
    final data = (response.data as Map<String, dynamic>)['contacts'] as List;
    return data.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Contact> getOne(int id) async {
    final response = await _api.get('/contacts/$id');
    return Contact.fromJson((response.data as Map<String, dynamic>)['contact'] as Map<String, dynamic>);
  }

  Future<Contact> create({
    required String firstName,
    String? lastName,
    required String phone,
    String? email,
    String? company,
    String stage = 'new',
    String? notes,
  }) async {
    final response = await _api.post('/contacts', data: {
      'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      'phone': phone,
      if (email != null) 'email': email,
      if (company != null) 'company': company,
      'stage': stage,
      if (notes != null) 'notes': notes,
    });
    return Contact.fromJson((response.data as Map<String, dynamic>)['contact'] as Map<String, dynamic>);
  }

  Future<Contact> update(int id, Map<String, dynamic> fields) async {
    final response = await _api.patch('/contacts/$id', data: fields);
    return Contact.fromJson((response.data as Map<String, dynamic>)['contact'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) => _api.delete('/contacts/$id');
}
