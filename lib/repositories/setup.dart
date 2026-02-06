import 'package:cloud_firestore/cloud_firestore.dart';

class AppSetupService {
  final FirebaseFirestore firestore;

  AppSetupService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedLookupIfNeeded(String userUid) async {
    final docRef = firestore
        .collection('users')
        .doc(userUid)
        .collection('settings')
        .doc('lookup');

    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set(defaultLookupData);
    }
  }
}

const defaultLookupData = {
  "paymentMethods": [
    {"id": "", "label": "—"},
    {"id": "card", "label": "Κάρτα"},
    {"id": "cash", "label": "Μετρητά"},
    {"id": "iris", "label": "IRIS"}
  ],
  "appointmentTypes": [
    {"id": "", "label": "—"},
    {"id": "katoikon", "label": "Σπίτι"},
    {"id": "grafeio", "label": "Γραφείο"}
  ],
  "incomeCategories": [
    {"id": "", "label": "—", "sort": 0},
    {"id": "eopyy", "label": "ΕΟΠΥΥ", "sort": 1}
  ],
  "expenseCategories": [
    {"id": "", "label": "—", "sort": 0},
    {"id": "pswnia", "label": "Ψώνια", "sort": 1},
    {"id": "xwrou", "label": "Χώρου", "sort": 2},
    {"id": "ypallhloi", "label": "Υπάλληλοι", "sort": 3},
    {"id": "genika", "label": "Γενικά Έξοδα", "sort": 4},
    {"id": "mhniaia", "label": "Μηνιαία", "sort": 5},
    {"id": "loipa", "label": "Λοιπά Έξοδα", "sort": 6}
  ],
  "expenseSubcategories": {
    "pswnia": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "market", "label": "Market", "sort": 1},
      {"id": "websites", "label": "Websites", "sort": 2},
      {"id": "xartika", "label": "Χαρτικά", "sort": 3},
      {"id": "ximika", "label": "Χημικά", "sort": 4},
      {"id": "analwsima", "label": "Αναλώσιμα", "sort": 5}
    ],
    "xwrou": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "rent", "label": "Ενοίκιο", "sort": 1},
      {"id": "deh", "label": "ΔΕΗ", "sort": 2},
      {"id": "nero", "label": "Νερό", "sort": 3}
    ],
    "ypallhloi": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "plhrwmh_mhna", "label": "Πληρωμή Μήνα", "sort": 1},
      {"id": "dwro_xrist", "label": "Δώρο Χριστουγέννων", "sort": 2},
      {"id": "dwro_pasxa", "label": "Δώρο Πάσχα", "sort": 3},
      {"id": "epidoma_adeias", "label": "Επίδομα Αδείας", "sort": 4},
      {"id": "katoikon", "label": "Κατοίκον", "sort": 5},
      {"id": "yperwria", "label": "Υπερωρία", "sort": 6}
    ],
    "genika": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "genika_eksoda", "label": "Γενικά Έξοδα", "sort": 1}
    ],
    "mhniaia": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "leasing", "label": "Leasing", "sort": 1},
      {"id": "daneio", "label": "Δάνειο", "sort": 2},
      {"id": "logisths", "label": "Λογιστής", "sort": 3}
    ],
    "loipa": [
      {"id": "", "label": "—", "sort": 0},
      {"id": "equipment", "label": "Equipment", "sort": 1},
      {"id": "efka", "label": "ΕΦΚΑ", "sort": 2},
      {"id": "fmy", "label": "ΦΜΥ", "sort": 3},
      {"id": "t_epitideum", "label": "Τέλος Επιτηδεύματος", "sort": 4}
    ]
  }
};
