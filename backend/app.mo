import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";

actor QuizApp {
  // Types
  type QuestionData = {
    soal: Text;
    jawaban: Text;
    kategori: Text;
    pilihan: ?[Text]; // Optional multiple choice
    tingkat: Text;
  };

  type QuizStats = {
    totalQuestions: Nat;
    correctAnswers: Nat;
    wrongAnswers: Nat;
    currentStreak: Nat;
    bestStreak: Nat;
    scorePercentage: Nat;
  };

  type QuizResult = {
    isCorrect: Bool;
    correctAnswer: Text;
    userAnswer: Text;
    message: Text;
    score: Nat;
    totalQuestions: Nat;
    streak: Nat;
  };

  type QuizResponse = {
    success: Bool;
    question: Text;
    category: Text;
    options: ?[Text];
    error: ?Text;
  };

  // State variables
  private stable var answerKey : Text = "";
  private stable var currentCategory : Text = "";
  private stable var currentQuestion : Text = "";
  private stable var totalQuestions : Nat = 0;
  private stable var correctAnswers : Nat = 0;
  private stable var wrongAnswers : Nat = 0;
  private stable var currentStreak : Nat = 0;
  private stable var bestStreak : Nat = 0;
  private stable var questionStartTime : Int = 0;

  // Expanded question bank to match the frontend
  private let questionBank : [(Text, [QuestionData])] = [
    ("matematika dasar", [
      {
        soal = "Berapa hasil dari 15 + 27?";
        jawaban = "42";
        kategori = "matematika dasar";
        pilihan = ?["40", "41", "42", "43"];
        tingkat = "SD";
      },
      {
        soal = "Jika ada 24 apel dan dimakan 9, berapa sisa apelnya?";
        jawaban = "15";
        kategori = "matematika dasar";
        pilihan = ?["14", "15", "16", "17"];
        tingkat = "SD";
      },
      {
        soal = "Berapa hasil dari 8 × 7?";
        jawaban = "56";
        kategori = "matematika dasar";
        pilihan = ?["54", "55", "56", "57"];
        tingkat = "SD";
      },
      {
        soal = "Berapa hasil dari 100 - 35?";
        jawaban = "65";
        kategori = "matematika dasar";
        pilihan = ?["63", "64", "65", "66"];
        tingkat = "SD";
      },
      {
        soal = "Berapa hasil dari 9 × 6?";
        jawaban = "54";
        kategori = "matematika dasar";
        pilihan = ?["52", "53", "54", "55"];
        tingkat = "SD";
      }
    ]),
    ("bahasa indonesia", [
      {
        soal = "Apa sinonim dari kata 'gembira'?";
        jawaban = "senang";
        kategori = "bahasa indonesia";
        pilihan = ?["sedih", "senang", "marah", "takut"];
        tingkat = "SD";
      },
      {
        soal = "Apa antonim dari kata 'tinggi'?";
        jawaban = "rendah";
        kategori = "bahasa indonesia";
        pilihan = ?["pendek", "rendah", "kecil", "sempit"];
        tingkat = "SD";
      },
      {
        soal = "Apa arti dari kata 'rajin'?";
        jawaban = "tekun";
        kategori = "bahasa indonesia";
        pilihan = ?["malas", "tekun", "cepat", "lambat"];
        tingkat = "SD";
      },
      {
        soal = "Apa antonim dari kata 'panas'?";
        jawaban = "dingin";
        kategori = "bahasa indonesia";
        pilihan = ?["hangat", "sejuk", "dingin", "lembab"];
        tingkat = "SD";
      },
      {
        soal = "Apa sinonim dari kata 'indah'?";
        jawaban = "cantik";
        kategori = "bahasa indonesia";
        pilihan = ?["jelek", "cantik", "buruk", "kotor"];
        tingkat = "SD";
      }
    ]),
    ("ilmu pengetahuan alam", [
      {
        soal = "Hewan apa yang bernapas dengan insang?";
        jawaban = "ikan";
        kategori = "ilmu pengetahuan alam";
        pilihan = ?["burung", "ikan", "kucing", "anjing"];
        tingkat = "SD";
      },
      {
        soal = "Tumbuhan apa yang bisa makan serangga?";
        jawaban = "kantong semar";
        kategori = "ilmu pengetahuan alam";
        pilihan = ?["mawar", "kantong semar", "melati", "anggrek"];
        tingkat = "SD";
      },
      {
        soal = "Planet apa yang terdekat dengan matahari?";
        jawaban = "merkurius";
        kategori = "ilmu pengetahuan alam";
        pilihan = ?["venus", "merkurius", "mars", "jupiter"];
        tingkat = "SD";
      },
      {
        soal = "Bagian tumbuhan yang berfungsi untuk menyerap air adalah?";
        jawaban = "akar";
        kategori = "ilmu pengetahuan alam";
        pilihan = ?["daun", "batang", "akar", "bunga"];
        tingkat = "SD";
      },
      {
        soal = "Hewan apa yang mengalami metamorfosis?";
        jawaban = "kupu-kupu";
        kategori = "ilmu pengetahuan alam";
        pilihan = ?["ayam", "kupu-kupu", "sapi", "kambing"];
        tingkat = "SD";
      }
    ]),
    ("sejarah indonesia", [
      {
        soal = "Siapa proklamator kemerdekaan Indonesia?";
        jawaban = "soekarno dan hatta";
        kategori = "sejarah indonesia";
        pilihan = ?["Soekarno dan Hatta", "Sudirman dan Soeharto", "Kartini dan Dewi Sartika", "Diponegoro dan Imam Bonjol"];
        tingkat = "SD";
      },
      {
        soal = "Kapan Indonesia merdeka?";
        jawaban = "17 agustus 1945";
        kategori = "sejarah indonesia";
        pilihan = ?["17 Agustus 1945", "1 Juni 1945", "20 Mei 1945", "28 Oktober 1945"];
        tingkat = "SD";
      },
      {
        soal = "Siapa pahlawan wanita dari Aceh?";
        jawaban = "cut nyak dhien";
        kategori = "sejarah indonesia";
        pilihan = ?["Cut Nyak Dhien", "Kartini", "Dewi Sartika", "Martha Christina Tiahahu"];
        tingkat = "SD";
      },
      {
        soal = "Siapa yang dijuluki Bapak Proklamator?";
        jawaban = "soekarno";
        kategori = "sejarah indonesia";
        pilihan = ?["Soekarno", "Hatta", "Sudirman", "Soeharto"];
        tingkat = "SD";
      },
      {
        soal = "Apa nama organisasi pemuda yang dibentuk tahun 1928?";
        jawaban = "sumpah pemuda";
        kategori = "sejarah indonesia";
        pilihan = ?["Boedi Oetomo", "Sumpah Pemuda", "Jong Java", "Indische Partij"];
        tingkat = "SD";
      }
    ]),
    ("geografi indonesia", [
      {
        soal = "Apa ibu kota Indonesia?";
        jawaban = "jakarta";
        kategori = "geografi indonesia";
        pilihan = ?["Bandung", "Surabaya", "Jakarta", "Medan"];
        tingkat = "SD";
      },
      {
        soal = "Pulau apa yang terbesar di Indonesia?";
        jawaban = "kalimantan";
        kategori = "geografi indonesia";
        pilihan = ?["Jawa", "Sumatera", "Kalimantan", "Sulawesi"];
        tingkat = "SD";
      },
      {
        soal = "Gunung apa yang tertinggi di Indonesia?";
        jawaban = "puncak jaya";
        kategori = "geografi indonesia";
        pilihan = ?["Gunung Merapi", "Puncak Jaya", "Gunung Bromo", "Gunung Rinjani"];
        tingkat = "SD";
      },
      {
        soal = "Laut apa yang berada di utara Jawa?";
        jawaban = "laut jawa";
        kategori = "geografi indonesia";
        pilihan = ?["Laut Jawa", "Laut Banda", "Laut Arafura", "Laut Timor"];
        tingkat = "SD";
      },
      {
        soal = "Selat apa yang memisahkan Jawa dan Sumatera?";
        jawaban = "selat sunda";
        kategori = "geografi indonesia";
        pilihan = ?["Selat Malaka", "Selat Sunda", "Selat Makassar", "Selat Bali"];
        tingkat = "SD";
      }
    ])
  ];

  let categories : [Text] = [
    "matematika dasar",
    "bahasa indonesia", 
    "ilmu pengetahuan alam",
    "sejarah indonesia",
    "geografi indonesia"
  ];

  // Helper functions
  private func getRandomCategory() : Text {
    let now : Int = Time.now();
    let count : Nat = categories.size();
    let index : Nat = Int.abs(now) % count;
    categories[index];
  };

  private func getRandomQuestion(category: Text) : ?QuestionData {
    for ((cat, questions) in questionBank.vals()) {
      if (Text.equal(cat, category)) {
        let now : Int = Time.now();
        let count : Nat = questions.size();
        let index : Nat = Int.abs(now) % count;
        return ?questions[index];
      };
    };
    null;
  };

  private func normalizeAnswer(answer: Text) : Text {
    let trimmed = Text.trim(answer, #char ' ');
    Text.toLowercase(trimmed);
  };

  private func isAnswerCorrect(userAnswer: Text, correctAnswer: Text) : Bool {
    let normalizedUser = normalizeAnswer(userAnswer);
    let normalizedCorrect = normalizeAnswer(correctAnswer);
    
    // Check exact match first
    if (Text.equal(normalizedUser, normalizedCorrect)) {
      return true;
    };
    
    // Check if user answer contains correct answer (for flexible matching)
    Text.contains(normalizedUser, #text normalizedCorrect) or
    Text.contains(normalizedCorrect, #text normalizedUser);
  };

  private func generateSuccessMessage(isCorrect: Bool) : Text {
    if (isCorrect) {
      let messages = [
        "🎉 Benar! Kamu hebat!",
        "👏 Bagus sekali!",
        "⭐ Jawaban yang tepat!",
        "🌟 Keren banget!",
        "💫 Pintar sekali!"
      ];
      let now : Int = Time.now();
      let index : Nat = Int.abs(now) % messages.size();
      messages[index];
    } else {
      let messages = [
        "❌ Belum tepat. Jangan menyerah, coba lagi!",
        "💪 Hampir benar! Terus belajar ya!",
        "🤔 Belum tepat, tapi jangan patah semangat!",
        "📚 Belajar lagi yuk! Kamu pasti bisa!",
        "🎯 Belum kena sasaran, tapi terus coba!"
      ];
      let now : Int = Time.now();
      let index : Nat = Int.abs(now) % messages.size();
      messages[index];
    };
  };

  // Public functions
  public func generateQuestion(preferredCategory: ?Text) : async QuizResponse {
    let category = switch (preferredCategory) {
      case (?cat) { cat };
      case null { getRandomCategory() };
    };

    switch (getRandomQuestion(category)) {
      case (?questionData) {
        answerKey := questionData.jawaban;
        currentCategory := questionData.kategori;
        currentQuestion := questionData.soal;
        questionStartTime := Time.now();
        
        {
          success = true;
          question = questionData.soal;
          category = questionData.kategori;
          options = questionData.pilihan;
          error = null;
        };
      };
      case null {
        {
          success = false;
          question = "";
          category = "";
          options = null;
          error = ?("Tidak ada soal untuk kategori: " # category);
        };
      };
    };
  };

  public func checkAnswer(userAnswer: Text) : async QuizResult {
    totalQuestions += 1;
    let isCorrect = isAnswerCorrect(userAnswer, answerKey);
    
    if (isCorrect) {
      correctAnswers += 1;
      currentStreak += 1;
      if (currentStreak > bestStreak) {
        bestStreak := currentStreak;
      };
    } else {
      wrongAnswers += 1;
      currentStreak := 0;
    };

    let scorePercentage = if (totalQuestions > 0) {
      (correctAnswers * 100) / totalQuestions;
    } else { 0 };

    {
      isCorrect = isCorrect;
      correctAnswer = answerKey;
      userAnswer = userAnswer;
      message = generateSuccessMessage(isCorrect);
      score = correctAnswers;
      totalQuestions = totalQuestions;
      streak = currentStreak;
    };
  };

  public query func getStats() : async QuizStats {
    let scorePercentage = if (totalQuestions > 0) {
      (correctAnswers * 100) / totalQuestions;
    } else { 0 };

    {
      totalQuestions = totalQuestions;
      correctAnswers = correctAnswers;
      wrongAnswers = wrongAnswers;
      currentStreak = currentStreak;
      bestStreak = bestStreak;
      scorePercentage = scorePercentage;
    };
  };

  public query func getCategories() : async [Text] {
    categories;
  };

  public query func getCurrentQuestion() : async Text {
    currentQuestion;
  };

  public query func getCurrentCategory() : async Text {
    currentCategory;
  };

  public query func getScore() : async { score: Nat; total: Nat } {
    {
      score = correctAnswers;
      total = totalQuestions;
    };
  };

  public func resetStats() : async () {
    totalQuestions := 0;
    correctAnswers := 0;
    wrongAnswers := 0;
    currentStreak := 0;
    // bestStreak is intentionally not reset to keep the all-time record
    answerKey := "";
    currentCategory := "";
    currentQuestion := "";
  };

  public func resetAll() : async () {
    totalQuestions := 0;
    correctAnswers := 0;
    wrongAnswers := 0;
    currentStreak := 0;
    bestStreak := 0;
    answerKey := "";
    currentCategory := "";
    currentQuestion := "";
  };

  // Get category icon (returns emoji as text)
  public query func getCategoryIcon(category: Text) : async Text {
    switch (category) {
      case "matematika dasar" { "🔢" };
      case "bahasa indonesia" { "📝" };
      case "ilmu pengetahuan alam" { "🔬" };
      case "sejarah indonesia" { "📜" };
      case "geografi indonesia" { "🌍" };
      case _ { "📚" };
    };
  };

  // Get all questions for a category (for debugging/admin)
  public query func getQuestionsByCategory(category: Text) : async [QuestionData] {
    for ((cat, questions) in questionBank.vals()) {
      if (Text.equal(cat, category)) {
        return questions;
      };
    };
    [];
  };

  // Get total questions available
  public query func getTotalAvailableQuestions() : async Nat {
    var total : Nat = 0;
    for ((_, questions) in questionBank.vals()) {
      total += questions.size();
    };
    total;
  };

  // Debug functions
  public query func getAnswerKey() : async Text {
    answerKey;
  };

  public query func debugInfo() : async Text {
    let percentage = if (totalQuestions > 0) {
      (correctAnswers * 100) / totalQuestions;
    } else { 0 };
    
    "📊 Stats: " # 
    "Total: " # Nat.toText(totalQuestions) # 
    " | Benar: " # Nat.toText(correctAnswers) # 
    " | Salah: " # Nat.toText(wrongAnswers) # 
    " | Streak: " # Nat.toText(currentStreak) # 
    " | Best: " # Nat.toText(bestStreak) # 
    " | Score: " # Nat.toText(percentage) # "%";
  };

  // Health check
  public query func healthCheck() : async Bool {
    true;
  };
};