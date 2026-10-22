import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/features/discover/listing.dart';

void main() {
  group('ListingFilters', () {
    test('omits empty filters and trims the search term', () {
      const filters = ListingFilters(query: '  cours  ', commune: 'Cocody');

      expect(filters.toQueryParameters(), {'q': 'cours', 'commune': 'Cocody'});
    });
  });

  group('Listing.fromJson', () {
    test('reads the public API representation without contact details', () {
      final listing = Listing.fromJson({
        'id': 12,
        'title': 'Réparation de ventilateur',
        'description': 'Recherche une personne pour réparer un ventilateur.',
        'type': 'DEMANDE',
        'nature': 'REMUNEREE',
        'commune': {'name': 'Cocody'},
        'category': {'name': 'Réparations'},
        'created_at': '2026-10-20T10:00:00Z',
      });

      expect(listing.id, 12);
      expect(listing.commune, 'Cocody');
      expect(listing.category, 'Réparations');
      expect(listing.type, 'DEMANDE');
    });
  });
}