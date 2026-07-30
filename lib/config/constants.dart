import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'PadiGuard';
  static const String appVersion = 'v1.0.0';
  
  // API Config
  static const bool useMockApi = false; // Set to true to run offline mock simulator
  static const String defaultBaseUrl = 'https://padiguard-tirza.up.railway.app/api/';

  /// Base URL dinamis: otomatis menyesuaikan domain/IP/Ngrok/Railway saat diakses lewat web
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host;
      if (host.isNotEmpty) {
        final scheme = uri.scheme;
        final port = uri.hasPort ? ':${uri.port}' : '';
        if (host == 'localhost' || host == '127.0.0.1') {
          return '$scheme://$host$port/padibackend/backend/api/';
        }
        return '$scheme://$host$port/api/';
      }
    }
    return defaultBaseUrl;
  }
  
  // Storage Keys
  static const String keyToken = 'jwt_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsFirstTime = 'is_first_time';
  
  // Static Tips
  static const List<Map<String, String>> agriculturalTips = [
    {
      'id': 'tip_1',
      'title': 'Cara Mengatasi Wereng Coklat Secara Alami',
      'desc': 'Wereng coklat dapat dikendalikan dengan menjaga jarak tanam, memanfaatkan musuh alami seperti laba-laba, dan menggunakan pestisida nabati dari ekstrak daun mimba atau gadung.',
      'category': 'Pengendalian Hama',
      'imageUrl': 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?auto=format&fit=crop&q=80&w=400',
      'readTime': '3 menit',
    },
    {
      'id': 'tip_2',
      'title': 'Mengenal Ciri Padi Siap Panen (Kematangan Matang)',
      'desc': 'Padi siap panen memiliki 90-95% butir gabah yang telah menguning. Kadar air gabah berkisar antara 21-24% dan batang tanaman mulai mengering secara alami.',
      'category': 'Tips Panen',
      'imageUrl': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=400',
      'readTime': '4 menit',
    },
    {
      'id': 'tip_3',
      'title': 'Pemupukan Berimbang untuk Padi Berkualitas',
      'desc': 'Berikan pupuk Urea, SP-36, dan KCl secara berimbang sesuai fase pertumbuhan tanaman padi (vegetatif dan generatif) untuk mengoptimalkan pengisian bulir gabah.',
      'category': 'Nutrisi Tanaman',
      'imageUrl': 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&q=80&w=400',
      'readTime': '5 menit',
    },
  ];

  // FAQ Content
  static const List<Map<String, String>> faqList = [
    {
      'question': 'Bagaimana cara melakukan scan padi?',
      'answer': 'Masuk ke menu "Scan" di navigation bar bawah, lalu pilih opsi Kamera untuk mengambil foto tanaman padi secara langsung atau Galeri untuk mengunggah gambar yang sudah ada. Pastikan gambar jelas dan berfokus pada hama atau bulir padi.',
    },
    {
      'question': 'Apakah aplikasi ini memerlukan koneksi internet?',
      'answer': 'Ya, saat ini aplikasi memerlukan koneksi internet untuk mengirimkan gambar padi ke server cloud yang memproses model deteksi YOLOv12.',
    },
    {
      'question': 'Apa itu model YOLOv12?',
      'answer': 'YOLOv12 (You Only Look Once version 12) adalah model deep learning terbaru dan sangat cepat yang digunakan untuk mendeteksi serta mengklasifikasi objek secara real-time, dalam hal ini mendeteksi lokasi hama serta menganalisis tingkat kematangan tanaman padi.',
    },
    {
      'question': 'Bagaimana cara mengunduh hasil riwayat?',
      'answer': 'Anda dapat membuka menu "Riwayat", menekan salah satu riwayat deteksi untuk melihat detail lengkap, dan menekan tombol simpan atau screenshot untuk membagikannya ke petani lain.',
    },
  ];

  // Pest Recommendations
  static const Map<String, Map<String, dynamic>> pestRecommendations = {
    'Wereng Coklat': {
      'danger_level': 'Tinggi',
      'description': 'Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.',
      'treatment': '1. Atur jarak tanam legowo untuk mengurangi kelembapan.\n2. Lestarikan musuh alami seperti laba-laba dan kumbang coccinellid.\n3. Jika populasi di atas ambang batas (15 ekor/rumpun), gunakan insektisida berbahan aktif pymetrozine atau imidacloprid sesuai dosis.',
    },
    'Walang Sangit': {
      'danger_level': 'Sedang',
      'description': 'Walang Sangit (Leptocorisa oratorius) menyerang bulir padi pada fase masak susu, menyebabkan bulir menjadi hampa atau bercorak coklat kehitaman.',
      'treatment': '1. Lakukan sanitasi lingkungan sawah dari rumput liar.\n2. Gunakan umpan bau-bauan (misal ikan busuk/kepiting) untuk menjebak walang sangit dewasa.\n3. Semprotkan pestisida nabati berbahan ekstrak serai wangi atau pestisida kimia berbahan aktif fipronil pada pagi/sore hari.',
    },
    'Penggerek Batang': {
      'danger_level': 'Tinggi',
      'description': 'Ulat penggerek batang padi (Scirpophaga innotata) merusak titik tumbuh tanaman. Serangan pada fase vegetatif menyebabkan "sundep" (batang layu/mati), dan pada fase generatif menyebabkan "beluk" (malai padi hampa dan putih).',
      'treatment': '1. Kumpulkan kelompok telur penggerek batang secara manual di persemaian.\n2. Tanam serentak untuk memutus siklus hidup hama.\n3. Gunakan agens hayati seperti parasitoid Trichogramma spp. atau insektisida sistemik berbahan aktif karbofuran jika serangan meluas.',
    },
    'Ulat Grayak': {
      'danger_level': 'Sedang',
      'description': 'Ulat Grayak (Spodoptera litura) memakan helai daun padi hingga hanya menyisakan tulang daun, biasanya menyerang dalam kelompok besar pada malam hari.',
      'treatment': '1. Genangi sawah sementara waktu untuk memaksa ulat naik ke atas tanaman agar mudah dimakan pemangsa alami.\n2. Gunakan patogen serangga Bacillus thuringiensis (Bt) sebagai pengendali hayati.\n3. Gunakan insektisida kimia berbahan aktif klorantraniliprol jika populasi melebihi ambang batas ekonomi.',
    },
  };

  // Maturity Info
  static const Map<String, Map<String, dynamic>> maturityDetails = {
    'Mentah': {
      'color_label': 'Hijau',
      'description': 'Tanaman padi berada pada fase pengisian bulir awal. Bulir masih berupa cairan bening atau cairan seperti susu. Belum siap panen.',
      'recommendation': 'Pastikan pasokan air tercukupi di sawah agar pengisian bulir berjalan optimal, lakukan pemupukan susulan NPK bila diperlukan, serta awasi serangan hama burung dan walang sangit.',
    },
    'Setengah Matang': {
      'color_label': 'Kuning Kehijauan',
      'description': 'Padi sedang memasuki fase masak kuning. Butir padi mulai mengeras dan sebagian besar mulai berwarna kuning, namun sebagian batang dan daun bendera masih hijau.',
      'recommendation': 'Mulai kurangi penggenangan air (keringkan sawah secara berkala) untuk mempercepat proses pematangan bulir gabah secara serentak.',
    },
    'Matang': {
      'color_label': 'Kuning Emas (Siap Panen)',
      'description': 'Tanaman padi telah mencapai fase masak penuh (matang fisiologis). Lebih dari 90% butir gabah telah menguning sempurna dan kadar air menurun.',
      'recommendation': 'Segera lakukan pemanenan dalam waktu 1-2 minggu ke depan untuk menghindari rontoknya gabah di sawah akibat terlalu kering atau penurunan kualitas akibat terendam hujan.',
    },
  };
}

