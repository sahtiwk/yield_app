import 'crop.dart';

// Offline reference catalog only. All harvest records come from farmer input.
const cropCatalog = [
  Crop(
    id: 'tomato',
    name: 'Tomato',
    variety: 'Arka Rakshak',
    varieties: ['Arka Rakshak', 'Pusa Ruby', 'Roma'],
  ),
  Crop(
    id: 'okra',
    name: 'Okra',
    variety: 'Arka Anamika',
    varieties: ['Arka Anamika', 'Pusa Sawani', 'Parbhani Kranti'],
  ),
  Crop(
    id: 'brinjal',
    name: 'Brinjal',
    variety: 'Pusa Purple Long',
    varieties: ['Pusa Purple Long', 'Arka Navneet', 'Bhagyamati'],
  ),
  Crop(
    id: 'onion',
    name: 'Onion',
    variety: 'Nashik Red',
    varieties: ['Nashik Red', 'Agrifound Dark Red', 'Bhima Shakti'],
  ),
  Crop(
    id: 'potato',
    name: 'Potato',
    variety: 'Kufri Jyoti',
    varieties: ['Kufri Jyoti', 'Kufri Pukhraj', 'Kufri Bahar'],
  ),
];
