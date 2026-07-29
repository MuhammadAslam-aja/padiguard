import 'dart:math';

class ApiMockData {
  static final ApiMockData _instance = ApiMockData._internal();
  factory ApiMockData() => _instance;
  ApiMockData._internal() {
    _initData();
  }

  // Users DB
  late List<Map<String, dynamic>> users;
  
  // Detections DB
  late List<Map<String, dynamic>> detections;

  // Dataset DB
  late List<Map<String, dynamic>> dataset;

  // Model Performance
  late Map<String, dynamic> modelPerformance;

  void _initData() {
    users = [
      {
        'id': 'u_1',
        'name': 'Budi Santoso',
        'email': 'petani@gmail.com',
        'password': 'petani123',
        'role': 'petani',
        'createdAt': '2026-05-10T08:30:00Z',
        'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Budi',
      },
      {
        'id': 'u_2',
        'name': 'Siti Rahma',
        'email': 'siti.petani@gmail.com',
        'password': 'password123',
        'role': 'petani',
        'createdAt': '2026-06-12T09:15:00Z',
        'avatar': 'https://api.dicebear.com/7.x/adventurer/png?seed=Siti',
      },
      {
        'id': 'u_3',
        'name': 'Admin PadiGuard',
        'email': 'admin@gmail.com',
        'password': 'admin123',
        'role': 'admin',
        'createdAt': '2026-04-01T07:00:00Z',
        'avatar': 'https://api.dicebear.com/7.x/bottts/png?seed=Admin',
      }
    ];

    detections = [
      {
        'id': 'd_1',
        'userEmail': 'petani@gmail.com',
        'userName': 'Budi Santoso',
        'date': '2026-06-25T10:30:00Z',
        'imageUrl': 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?auto=format&fit=crop&q=80&w=500',
        'hamaName': 'Wereng Coklat',
        'hamaConfidence': 0.88,
        'kematangan': 'Setengah Matang',
        'kematanganConfidence': 0.94,
        'boundingBoxes': [
          {'label': 'Wereng Coklat (88%)', 'xMin': 0.2, 'yMin': 0.3, 'xMax': 0.5, 'yMax': 0.6, 'isHama': true},
          {'label': 'Setengah Matang (94%)', 'xMin': 0.1, 'yMin': 0.1, 'xMax': 0.9, 'yMax': 0.9, 'isHama': false},
        ],
        'dangerLevel': 'Tinggi',
        'description': 'Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.',
        'treatment': '1. Atur jarak tanam legowo untuk mengurangi kelembapan.\n2. Lestarikan musuh alami seperti laba-laba.\n3. Semprotkan insektisida pymetrozine jika populasi tinggi.',
      },
      {
        'id': 'd_2',
        'userEmail': 'petani@gmail.com',
        'userName': 'Budi Santoso',
        'date': '2026-06-26T08:15:00Z',
        'imageUrl': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=500',
        'hamaName': null,
        'hamaConfidence': 0.0,
        'kematangan': 'Matang',
        'kematanganConfidence': 0.97,
        'boundingBoxes': [
          {'label': 'Matang (97%)', 'xMin': 0.05, 'yMin': 0.05, 'xMax': 0.95, 'yMax': 0.95, 'isHama': false},
        ],
        'dangerLevel': 'Aman',
        'description': 'Tanaman padi telah mencapai fase masak penuh (matang fisiologis). Lebih dari 90% butir gabah telah menguning sempurna dan kadar air menurun.',
        'treatment': 'Segera lakukan pemanenan dalam waktu 1-2 minggu ke depan untuk menghindari rontoknya gabah.',
      },
      {
        'id': 'd_3',
        'userEmail': 'siti.petani@gmail.com',
        'userName': 'Siti Rahma',
        'date': '2026-06-24T14:20:00Z',
        'imageUrl': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=500',
        'hamaName': 'Walang Sangit',
        'hamaConfidence': 0.76,
        'kematangan': 'Mentah',
        'kematanganConfidence': 0.91,
        'boundingBoxes': [
          {'label': 'Walang Sangit (76%)', 'xMin': 0.4, 'yMin': 0.4, 'xMax': 0.7, 'yMax': 0.7, 'isHama': true},
          {'label': 'Mentah (91%)', 'xMin': 0.1, 'yMin': 0.1, 'xMax': 0.85, 'yMax': 0.85, 'isHama': false},
        ],
        'dangerLevel': 'Sedang',
        'description': 'Walang Sangit (Leptocorisa oratorius) menyerang bulir padi pada fase masak susu, menyebabkan bulir menjadi hampa.',
        'treatment': '1. Lakukan sanitasi sawah dari rumput liar.\n2. Pasang umpan bau bau ikan busuk.\n3. Semprot pestisida nabati.',
      }
    ];

    dataset = [
      {
        'id': 'ds_1',
        'imageUrl': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=200',
        'label': 'Mentah - Walang Sangit',
        'uploadDate': '2026-06-20T10:00:00Z'
      },
      {
        'id': 'ds_2',
        'imageUrl': 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=200',
        'label': 'Matang - Sehat',
        'uploadDate': '2026-06-21T11:30:00Z'
      },
      {
        'id': 'ds_3',
        'imageUrl': 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?w=200',
        'label': 'Setengah Matang - Wereng Coklat (Spot Hopperburn)',
        'uploadDate': '2026-06-22T09:15:00Z'
      },
      {
        'id': 'ds_4',
        'imageUrl': 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?w=200',
        'label': 'Mentah - Sehat',
        'uploadDate': '2026-06-23T14:20:00Z'
      },
      {
        'id': 'ds_5',
        'imageUrl': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=200',
        'label': 'Setengah Matang - Pematang Sawah (Normal)',
        'uploadDate': '2026-06-24T16:45:00Z'
      },
      {
        'id': 'ds_6',
        'imageUrl': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=200',
        'label': 'Matang - Ulat Grayak',
        'uploadDate': '2026-06-25T08:10:00Z'
      },
      {
        'id': 'ds_7',
        'imageUrl': 'https://images.unsplash.com/photo-1500627869374-13cd993b1115?w=200',
        'label': 'Setengah Matang - Penggerek Batang',
        'uploadDate': '2026-06-26T10:30:00Z'
      },
      {
        'id': 'ds_8',
        'imageUrl': 'https://images.unsplash.com/photo-1475113548554-5a36f1f523d6?w=200',
        'label': 'Matang - Spot Rusak Wereng',
        'uploadDate': '2026-06-27T11:50:00Z'
      },
      {
        'id': 'ds_9',
        'imageUrl': 'api/image?file=det_6a53cba3f095a_1783876515.png',
        'label': 'Matang - Wereng Coklat (Spot Hopperburn)',
        'uploadDate': '2026-07-13T01:15:00Z'
      },
      {
        'id': 'ds_10',
        'imageUrl': 'api/image?file=det_6a53cb0f7da86_1783876367.png',
        'label': 'Setengah Matang - Wereng Coklat (Kerusakan Batang)',
        'uploadDate': '2026-07-13T01:12:00Z'
      },
      {
        'id': 'ds_11',
        'imageUrl': 'api/image?file=det_6a53ca86dae85_1783876230.png',
        'label': 'Matang - Wereng Coklat (Hopperburn Berat)',
        'uploadDate': '2026-07-13T01:10:00Z'
      },
      {
        'id': 'ds_12',
        'imageUrl': 'api/image?file=det_6a53d00f24188_1783877647.png',
        'label': 'Matang - Wereng Coklat (Kerusakan Jalur)',
        'uploadDate': '2026-07-13T01:34:00Z'
      },
      {
        'id': 'ds_13',
        'imageUrl': 'api/image?file=det_6a53d079bf274_1783877753.jpeg',
        'label': 'Matang - Wereng Coklat (Batang Menguning)',
        'uploadDate': '2026-07-13T01:35:00Z'
      },
      {
        'id': 'ds_14',
        'imageUrl': 'api/image?file=det_6a53d0c70e83f_1783877831.png',
        'label': 'Matang - Wereng Coklat (Spot Kering Awal)',
        'uploadDate': '2026-07-13T01:37:00Z'
      },
      {
        'id': 'ds_15',
        'imageUrl': 'api/image?file=det_6a53d2b808fd2_1783878328.jpeg',
        'label': 'Matang - Sehat',
        'uploadDate': '2026-07-13T01:45:00Z'
      },
      {
        'id': 'ds_16',
        'imageUrl': 'api/image?file=det_6a550c0e721bc_1783958542.jpeg',
        'label': 'Setengah Matang - Pematang Sawah (Normal)',
        'uploadDate': '2026-07-14T00:02:00Z'
      }
    ];

    modelPerformance = {
      'accuracy': 0.962,
      'precision': 0.948,
      'recall': 0.938,
      'f1Score': 0.943,
      'epoch': 100,
      'learningRate': 0.001,
      'datasetCount': 8766,
      'lastTrained': '2026-06-29T19:19:00Z',
    };
  }

  // Auth Operations
  Map<String, dynamic>? authenticate(String email, String password) {
    try {
      final user = users.firstWhere(
        (u) => u['email'].toString().toLowerCase() == email.trim().toLowerCase() && u['password'] == password
      );
      return user;
    } catch (_) {
      return null;
    }
  }

  bool register(String name, String email, String password, String role) {
    if (users.any((u) => u['email'].toString().toLowerCase() == email.trim().toLowerCase())) {
      return false; // User exists
    }
    users.add({
      'id': 'u_${users.length + 1}',
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
      'avatar': 'https://api.dicebear.com/7.x/adventurer/svg?seed=$name',
    });
    return true;
  }

  Map<String, dynamic>? getUserByEmail(String email) {
    try {
      return users.firstWhere((u) => u['email'].toString().toLowerCase() == email.trim().toLowerCase());
    } catch (_) {
      return null;
    }
  }

  bool updateProfile(String email, String name, String? newPassword) {
    try {
      final index = users.indexWhere((u) => u['email'].toString().toLowerCase() == email.trim().toLowerCase());
      if (index != -1) {
        users[index]['name'] = name;
        if (newPassword != null && newPassword.isNotEmpty) {
          users[index]['password'] = newPassword;
        }
        // Update user name in detections history as well
        for (var det in detections) {
          if (det['userEmail'] == email) {
            det['userName'] = name;
          }
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Detection Operations
  List<Map<String, dynamic>> getDetectionHistory(String? email) {
    if (email == null) {
      return List.from(detections);
    }
    return detections.where((d) => d['userEmail'] == email).toList();
  }

  Map<String, dynamic>? getDetectionById(String id) {
    try {
      return detections.firstWhere((d) => d['id'] == id);
    } catch (_) {
      return null;
    }
  }

  bool deleteDetection(String id) {
    final lengthBefore = detections.length;
    detections.removeWhere((d) => d['id'] == id);
    return detections.length < lengthBefore;
  }

  Map<String, dynamic> addMockDetection(String userEmail, String userName, String? imagePath) {
    // Generate a random detection outcome
    final listHama = ['Wereng Coklat', 'Walang Sangit', 'Penggerek Batang', 'Ulat Grayak', null];
    final listKematangan = ['Mentah', 'Setengah Matang', 'Matang'];
    
    final random = Random();
    final hama = listHama[random.nextInt(listHama.length)];
    final kematangan = listKematangan[random.nextInt(listKematangan.length)];
    final hamaConf = hama != null ? 0.70 + random.nextDouble() * 0.25 : 0.0;
    final kematanganConf = 0.80 + random.nextDouble() * 0.18;

    final String id = 'd_${detections.length + 1}';
    
    // Choose dummy image
    String dummyImg = 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=500';
    if (hama != null) {
      dummyImg = 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?auto=format&fit=crop&q=80&w=500';
    } else if (kematangan == 'Matang') {
      dummyImg = 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&q=80&w=500';
    }

    // Set bounding boxes
    final List<Map<String, dynamic>> boxes = [];
    if (hama != null) {
      boxes.add({
        'label': '$hama (${(hamaConf * 100).toStringAsFixed(0)}%)',
        'xMin': 0.2 + random.nextDouble() * 0.1,
        'yMin': 0.3 + random.nextDouble() * 0.1,
        'xMax': 0.6 + random.nextDouble() * 0.2,
        'yMax': 0.7 + random.nextDouble() * 0.2,
        'isHama': true
      });
    }
    boxes.add({
      'label': '$kematangan (${(kematanganConf * 100).toStringAsFixed(0)}%)',
      'xMin': 0.05,
      'yMin': 0.05,
      'xMax': 0.95,
      'yMax': 0.95,
      'isHama': false
    });

    // Details
    String danger = 'Aman';
    String desc = 'Tanaman padi dalam kondisi sehat tanpa serangan hama yang terdeteksi.';
    String treatment = 'Lanjutkan pemeliharaan rutin, penyiangan gulma, dan pemantauan berkala.';
    
    if (hama != null) {
      if (hama == 'Wereng Coklat' || hama == 'Penggerek Batang') {
        danger = 'Tinggi';
      } else {
        danger = 'Sedang';
      }
      
      switch (hama) {
        case 'Wereng Coklat':
          desc = 'Wereng Coklat (Nilaparvata lugens) menghisap cairan tanaman padi menyebabkan daun menguning, mengering (hopperburn), dan tanaman mati.';
          treatment = '1. Atur jarak tanam legowo untuk mengurangi kelembapan.\n2. Lestarikan musuh alami seperti laba-laba.\n3. Semprotkan insektisida pymetrozine jika populasi tinggi.';
          break;
        case 'Walang Sangit':
          desc = 'Walang Sangit (Leptocorisa oratorius) menyerang bulir padi pada fase masak susu, menyebabkan bulir menjadi hampa.';
          treatment = '1. Lakukan sanitasi sawah dari rumput liar.\n2. Pasang umpan bau bau ikan busuk.\n3. Semprot pestisida nabati.';
          break;
        case 'Penggerek Batang':
          desc = 'Ulat penggerek batang padi (Scirpophaga innotata) merusak titik tumbuh tanaman, menyebabkan sundep atau beluk.';
          treatment = '1. Kumpulkan kelompok telur penggerek secara manual.\n2. Tanam serentak untuk memutus siklus hidup hama.\n3. Gunakan agens hayati Trichogramma spp.';
          break;
        case 'Ulat Grayak':
          desc = 'Ulat Grayak (Spodoptera litura) memakan helai daun padi hingga hanya menyisakan tulang daun.';
          treatment = '1. Genangi sawah sementara waktu.\n2. Gunakan patogen Bacillus thuringiensis (Bt).\n3. Semprot klorantraniliprol jika serangan meluas.';
          break;
      }
    } else {
      // No pest
      switch (kematangan) {
        case 'Mentah':
          desc = 'Tanaman padi berada pada fase pengisian bulir awal. Bulir masih berupa cairan bening atau susu. Belum siap panen.';
          treatment = 'Pastikan pasokan air sawah tercukupi untuk pengisian bulir optimal.';
          break;
        case 'Setengah Matang':
          desc = 'Padi sedang memasuki fase masak kuning. Sebagian besar mulai menguning, batang/daun masih agak hijau.';
          treatment = 'Kurangi penggenangan air secara berkala untuk mempercepat pematangan serentak.';
          break;
        case 'Matang':
          desc = 'Padi telah mencapai fase masak penuh (matang fisiologis). Gabah menguning sempurna.';
          treatment = 'Segera lakukan pemanenan dalam 1-2 minggu ke depan.';
          break;
      }
    }

    final newDet = {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'date': DateTime.now().toIso8601String(),
      'imageUrl': dummyImg,
      'hamaName': hama,
      'hamaConfidence': hamaConf,
      'kematangan': kematangan,
      'kematanganConfidence': kematanganConf,
      'boundingBoxes': boxes,
      'dangerLevel': danger,
      'description': desc,
      'treatment': treatment,
    };

    detections.insert(0, newDet); // Insert at top
    return newDet;
  }

  // Admin Dashboard Statistics
  Map<String, dynamic> getAdminDashboardStats() {
    final totalDetections = detections.length;
    final totalUsers = users.where((u) => u['role'] == 'petani').length;
    
    // Hama count
    final Map<String, int> hamaCounts = {};
    for (var d in detections) {
      if (d['hamaName'] != null) {
        final hama = d['hamaName'] as String;
        hamaCounts[hama] = (hamaCounts[hama] ?? 0) + 1;
      }
    }
    
    String mostCommonHama = 'Tidak Ada';
    int maxHamaCount = 0;
    hamaCounts.forEach((k, v) {
      if (v > maxHamaCount) {
        maxHamaCount = v;
        mostCommonHama = k;
      }
    });

    // Kematangan count
    final Map<String, int> kematanganCounts = {};
    for (var d in detections) {
      final kem = d['kematangan'] as String;
      kematanganCounts[kem] = (kematanganCounts[kem] ?? 0) + 1;
    }

    String dominantMaturity = 'Mentah';
    int maxKemCount = 0;
    kematanganCounts.forEach((k, v) {
      if (v > maxKemCount) {
        maxKemCount = v;
        dominantMaturity = k;
      }
    });

    return {
      'totalDetections': totalDetections,
      'totalUsers': totalUsers,
      'mostCommonHama': mostCommonHama,
      'dominantMaturity': dominantMaturity,
      'hamaDistribution': hamaCounts,
      'maturityDistribution': kematanganCounts,
      'weeklyDetections': [
        {'day': 'Sen', 'count': 4},
        {'day': 'Sel', 'count': 3},
        {'day': 'Rab', 'count': 6},
        {'day': 'Kam', 'count': 5},
        {'day': 'Jum', 'count': 8},
        {'day': 'Sab', 'count': 10},
        {'day': 'Min', 'count': 7},
      ]
    };
  }

  // Admin CRUD Users
  List<Map<String, dynamic>> getAllUsers() {
    return List.from(users);
  }

  bool deleteUser(String id) {
    final lengthBefore = users.length;
    users.removeWhere((u) => u['id'] == id);
    return users.length < lengthBefore;
  }

  bool adminAddUser(String name, String email, String password, String role) {
    return register(name, email, password, role);
  }

  bool adminUpdateUser(String id, String name, String email, String role, String? password) {
    final idx = users.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      users[idx]['name'] = name;
      users[idx]['email'] = email;
      users[idx]['role'] = role;
      if (password != null && password.isNotEmpty) {
        users[idx]['password'] = password;
      }
      return true;
    }
    return false;
  }

  // Dataset Operations
  List<Map<String, dynamic>> getDatasetList() {
    return List.from(dataset);
  }

  void uploadDataset(String label, String? dummyPath) {
    final random = Random();
    final dummyImages = [
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=200',
      'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=200',
      'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?w=200',
    ];
    
    dataset.insert(0, {
      'id': 'ds_${dataset.length + 1}',
      'imageUrl': dummyImages[random.nextInt(dummyImages.length)],
      'label': label,
      'uploadDate': DateTime.now().toIso8601String(),
    });

    modelPerformance['datasetCount'] = modelPerformance['datasetCount'] + 1;
  }

  // Retrain Model Mock
  Future<Map<String, dynamic>> triggerRetrain() async {
    await Future.delayed(const Duration(seconds: 3));
    final random = Random();
    
    // Slightly improve metrics to simulate training improvement
    final double accInc = random.nextDouble() * 0.01;
    final double precInc = random.nextDouble() * 0.01;
    final double recInc = random.nextDouble() * 0.01;
    
    modelPerformance['accuracy'] = min(0.99, modelPerformance['accuracy'] + accInc);
    modelPerformance['precision'] = min(0.99, modelPerformance['precision'] + precInc);
    modelPerformance['recall'] = min(0.99, modelPerformance['recall'] + recInc);
    modelPerformance['f1Score'] = (2 * modelPerformance['accuracy'] * modelPerformance['precision']) / (modelPerformance['accuracy'] + modelPerformance['precision']);
    modelPerformance['epoch'] = modelPerformance['epoch'] + 50;
    modelPerformance['lastTrained'] = DateTime.now().toIso8601String();
    
    return modelPerformance;
  }
}
