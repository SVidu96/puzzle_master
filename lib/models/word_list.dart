import 'dart:math';

class WordList {
  static final List<String> easyWords = [
    'apple', 'house', 'water', 'music', 'happy', 'smile', 'light', 'dream', 'peace', 'heart',
    'cloud', 'beach', 'chair', 'table', 'phone', 'bread', 'candy', 'stars', 'juice', 'green',
    'clock', 'piano', 'dance', 'movie', 'plant', 'shirt', 'socks', 'books', 'teeth', 'zebra',
    'lemon', 'grass', 'paint', 'tiger', 'grape', 'spoon', 'couch', 'truck', 'mouse', 'panda',
    'towel', 'drums', 'glove', 'floor', 'purse', 'brush', 'ruler', 'sugar', 'honey', 'earth',
    'chalk', 'cabin', 'crown', 'drink', 'paper', 'block', 'crayon', 'flame', 'jelly', 'knife',
    'radio', 'scarf', 'shelf', 'space', 'whale', 'train', 'snack', 'tooth', 'woods', 'sheep',
    'swing', 'track', 'petal', 'field', 'queen', 'match', 'stars', 'socks', 'light', 'flute',
    'candy', 'lunch', 'berry', 'boots', 'pouch', 'broom', 'scoop', 'noise', 'story', 'shell',
    'piano', 'purse', 'cabin', 'zebra', 'fruit', 'wagon', 'water', 'tiger', 'drill', 'chalk'
  ];

  static final List<String> mediumWords = [
    'garden', 'purple', 'orange', 'yellow', 'window', 'pencil', 'school', 'friend', 'family', 'summer',
    'winter', 'spring', 'autumn', 'dinner', 'breakfast', 'pillow', 'castle', 'bridge', 'flower', 'rocket',
    'planet', 'ticket', 'butter', 'banana', 'glider', 'jungle', 'mirror', 'silver', 'cheese', 'artist',
    'circle', 'animal', 'cookie', 'kitten', 'sister', 'candle', 'guitar', 'hunter', 'bucket', 'engine',
    'travel', 'forest', 'rabbit', 'closet', 'button', 'pickle', 'goblet', 'magnet', 'pirate', 'feather',
    'island', 'sunset', 'statue', 'wallet', 'pencil', 'blanket', 'voyage', 'castle', 'garage', 'laptop',
    'handle', 'window', 'bottle', 'finger', 'pastel', 'saddle', 'temple', 'ladder', 'circle', 'shovel',
    'helmet', 'throat', 'camera', 'farmer', 'vessel', 'lantern', 'tablet', 'rubber', 'parrot', 'napkin',
    'outfit', 'cactus', 'cereal', 'cousin', 'market', 'planet', 'singer', 'shower', 'ticket', 'vacuum',
    'rocket', 'puzzle', 'castle', 'forest', 'butter', 'artist', 'donkey', 'bubble', 'circle', 'window'
  ];

  static final List<String> hardWords = [
    'beautiful', 'chocolate', 'elephant', 'giraffe', 'butterfly', 'dinosaur', 'umbrella', 'computer', 'keyboard', 'notebook',
    'calendar', 'birthday', 'holiday', 'vacation', 'adventure', 'backpack', 'carousel', 'triangle', 'building', 'alligator',
    'binoculars', 'volcano', 'mountains', 'sandwich', 'firework', 'chandelier', 'hurricane', 'microwave', 'astronaut', 'refrigerator',
    'telephone', 'whirlpool', 'playground', 'snowflake', 'blueberry', 'lighthouse', 'calculator', 'reception', 'celebrate', 'campfire',
    'scarecrow', 'helicopter', 'electricity', 'conversation', 'revolution', 'motorcycle', 'construction', 'electrician', 'information', 'vocabulary',
    'destination', 'microscope', 'contribution', 'grandmother', 'friendship', 'distribution', 'imagination', 'personality', 'investigate', 'controller',
    'submarine', 'population', 'temperature', 'volleyball', 'relationship', 'photograph', 'instrument', 'technology', 'navigation', 'journalist',
    'invention', 'compass', 'philosophy', 'understand', 'windshield', 'lightbulb', 'chocolatey', 'typography', 'breakfast', 'basketball',
    'restaurant', 'sunscreen', 'electrician', 'earthquake', 'photograph', 'skyscraper', 'achievement', 'calculator', 'architecture', 'foundation',
    'conversation', 'conclusion', 'nightlight', 'experiment', 'backpacker', 'interview', 'reception', 'definition', 'civilization', 'democracy'
  ];

  static String getRandomWord(String difficulty) {
    final random = Random();
    List<String> words;
    
    switch (difficulty) {
      case 'easy':
        words = easyWords;
        break;
      case 'medium':
        words = mediumWords;
        break;
      case 'hard':
        words = hardWords;
        break;
      default:
        words = easyWords;
    }
    
    return words[random.nextInt(words.length)];
  }
} 