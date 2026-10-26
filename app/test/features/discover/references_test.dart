import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

void main() {
  test('ReferenceItem parses the API payload', () {
    final item = ReferenceItem.fromJson({
      'id': 7,
      'name': 'Cocody',
      'description': null,
    });

    expect(item.id, 7);
    expect(item.name, 'Cocody');
    expect(item.description, isNull);
  });

  test('ReferenceItem parses the category description', () {
    final item = ReferenceItem.fromJson({
      'id': 3,
      'name': 'Éducation et cours',
      'description': 'Cours particuliers et soutien scolaire.',
    });

    expect(item.description, 'Cours particuliers et soutien scolaire.');
  });

  test('ReferenceItem parses the service icon key', () {
    final item = ReferenceItem.fromJson({
      'id': 9,
      'name': 'Plomberie et sanitaire',
      'description': 'Fuites et sanitaires à domicile.',
      'icon': 'plumbing',
    });

    expect(item.icon, 'plumbing');

    final commune = ReferenceItem.fromJson({'id': 1, 'name': 'Abobo'});

    expect(commune.icon, isNull);
  });

  test('ListingFilters sends the category id and keeps equality', () {
    const withCategory = ListingFilters(query: 'cours', category: 3);
    const sameCategory = ListingFilters(query: 'cours', category: 3);
    const otherCategory = ListingFilters(query: 'cours', category: 4);
    const withoutCategory = ListingFilters(query: 'cours');

    expect(withCategory.toQueryParameters(), {
      'q': 'cours',
      'category': 3,
    });
    expect(withoutCategory.toQueryParameters(), {'q': 'cours'});
    expect(withCategory, sameCategory);
    expect(withCategory, isNot(otherCategory));
    expect(withoutCategory, isNot(withCategory));
    expect(withCategory.hashCode, sameCategory.hashCode);
  });
}
