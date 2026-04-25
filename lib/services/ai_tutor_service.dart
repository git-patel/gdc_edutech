import 'package:google_generative_ai/google_generative_ai.dart';
import 'onboarding_storage.dart';

class AITutorService {
  // TODO: Replace with actual Gemini API Key from environment or secure storage
  static const String _apiKey = 'Can not add api key due to privacyissue pleasecheck in application';
  
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  Future<void> initialize({String? subject, String? chapter}) async {
    // We retrieve user profile to personalize the System Prompt.
    final profile = await OnboardingStorage.getProfile();
    final name = profile['name'] ?? 'Student';
    final goal = profile['goal'] ?? 'learning general concepts';
    final standard = profile['standard'] ?? '';

    String contextAwareness = '';
    if (subject != null && chapter != null) {
      contextAwareness = "\n**CURRENT CONTEXT**: The user is currently viewing the chapter '$chapter' for the subject '$subject'. Tailor your initial responses exactly to this content.";
    }

    // The Profiler Agent: Constructing the dynamic system instruction
    final systemInstruction = '''
You are "Agentic Tutor", an advanced, highly personalized AI educator.
You are tutoring $name, who is studying in Class $standard and has a primary goal of: $goal.$contextAwareness

Your core directives:
1. **Adaptive Pacing:** Constantly evaluate cognitive load. If the user asks "I don't get it" or gives a wrong answer, break the concept down into a micro-lesson. If they answer correctly, accelerate the pace and move to more advanced topics.
2. **Hyper-Personalization:** Use analogies related to their goal ($goal). E.g., if they like cricket/sports, explain physics or math using cricket.
3. **Socratic Interactivity:** Never just give the final answer. Ask guiding questions. Make them think.
4. **Formatting:** Use Markdown extensively (bolding, lists) to make text readable. Output short, digestible chunks.
''';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Uses the modern, faster model
      apiKey: _apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    _chatSession = _model.startChat();
  }

  /// Sends a message and returns the response stream.
  Stream<String> sendMessageStream(String message) async* {
    if (_chatSession == null) {
      await initialize();
    }

    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      // Mocked response for UI demonstration if key is not set.
      yield* _mockResponseStream(message);
      return;
    }

    try {
      final content = Content.text(message);
      final responseStream = _chatSession!.sendMessageStream(content);
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print(e);
      yield 'Error: Unable to connect to the Agentic Tutor. Please check your network or API key configuration. $e';
    }
  }

  Stream<String> _mockResponseStream(String input) async* {
    await Future.delayed(const Duration(milliseconds: 500));
    final lowerInput = input.toLowerCase();
    
    String response = '';
    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      response = "Hello! I am your Agentic Tutor. I see you are aiming for your goals. What new concept would you like to master today? I'll make sure to adjust to your pace!";
    } else if (lowerInput.contains('photosynthesis') || lowerInput.contains('science')) {
      response = "Great choice! Let's talk about Photosynthesis.\n\nImagine a solar panel on a house. Plants have something similar called **chlorophyll**. It captures sunlight to create energy (food) from water and carbon dioxide.\n\nCan you guess what the 'exhaust' or byproduct of this process is, which is super helpful to humans?";
    } else if (lowerInput.contains('oxygen')) {
      response = "Spot on! That's exactly right.\n\nSince you got that so quickly, let's accelerate. The process actually involves a Light-dependent reaction and the Calvin cycle. \n\nWhich of these do you think requires direct sunlight to produce ATP?";
    } else {
      response = "Interesting point! Let's break that down. To help me adjust our pace, could you tell me what specific part of this topic feels confusing right now? Remember, we can take it one step at a time.";
    }

    // Simulate streaming word by word
    final words = response.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield '$word ';
    }
  }
}
