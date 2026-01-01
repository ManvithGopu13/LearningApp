package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ============================================================================
// MODELS
// ============================================================================

// User represents a user in the system
type User struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    string             `bson:"user_id" json:"userId"`
	Name      string             `bson:"name" json:"name"`
	CreatedAt time.Time          `bson:"created_at" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updated_at" json:"updatedAt"`
}

// Chapter represents a learning chapter
type Chapter struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ChapterID   string             `bson:"chapter_id" json:"chapterId"`
	Title       string             `bson:"title" json:"title"`
	Description string             `bson:"description" json:"description"`
	VideoURL    string             `bson:"video_url" json:"videoUrl"`
	Duration    int                `bson:"duration" json:"duration"` // in seconds
	Quiz        Quiz               `bson:"quiz" json:"quiz"`
	Order       int                `bson:"order" json:"order"`
}

// Quiz represents a quiz for a chapter
type Quiz struct {
	Questions []Question `bson:"questions" json:"questions"`
}

// Question represents a single quiz question
type Question struct {
	ID            string   `bson:"id" json:"id"`
	QuestionText  string   `bson:"question_text" json:"questionText"`
	Options       []string `bson:"options" json:"options"`
	CorrectAnswer int      `bson:"correct_answer" json:"correctAnswer"`
}

// Progress represents user's learning progress
type Progress struct {
	ID               primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID           string             `bson:"user_id" json:"userId"`
	ChapterID        string             `bson:"chapter_id" json:"chapterId"`
	VideoProgress    int                `bson:"video_progress" json:"videoProgress"` // in seconds
	VideoCompleted   bool               `bson:"video_completed" json:"videoCompleted"`
	QuizProgress     int                `bson:"quiz_progress" json:"quizProgress"` // current question index
	QuizAnswers      []int              `bson:"quiz_answers" json:"quizAnswers"`   // user's answers
	QuizCompleted    bool               `bson:"quiz_completed" json:"quizCompleted"`
	ChapterCompleted bool               `bson:"chapter_completed" json:"chapterCompleted"`
	LastAccessedAt   time.Time          `bson:"last_accessed_at" json:"lastAccessedAt"`
	UpdatedAt        time.Time          `bson:"updated_at" json:"updatedAt"`
}

// ============================================================================
// REQUEST/RESPONSE MODELS
// ============================================================================

type LoginRequest struct {
	UserID string `json:"userId"`
	Name   string `json:"name"`
}

type LoginResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	User    User   `json:"user"`
}

type UpdateVideoProgressRequest struct {
	UserID    string `json:"userId"`
	ChapterID string `json:"chapterId"`
	Progress  int    `json:"progress"` // in seconds
	Completed bool   `json:"completed"`
}

type UpdateQuizProgressRequest struct {
	UserID        string `json:"userId"`
	ChapterID     string `json:"chapterId"`
	QuestionIndex int    `json:"questionIndex"`
	Answer        int    `json:"answer"`
	Completed     bool   `json:"completed"`
}

type GetProgressResponse struct {
	Success  bool       `json:"success"`
	Progress []Progress `json:"progress"`
}

type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// ============================================================================
// DATABASE CONNECTION
// ============================================================================

var (
	client      *mongo.Client
	database    *mongo.Database
	usersCol    *mongo.Collection
	chaptersCol *mongo.Collection
	progressCol *mongo.Collection
)

// InitDB initializes the MongoDB connection
func InitDB() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db_conn := godotenv.Load()
	if db_conn != nil {
		log.Println("⚠️ No .env file found, using system environment variables")
	}

	// MongoDB connection string - use environment variable or default
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	var err error
	client, err = mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		return fmt.Errorf("failed to connect to MongoDB: %w", err)
	}

	// Ping the database
	err = client.Ping(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to ping MongoDB: %w", err)
	}

	database = client.Database("resume_learning")
	usersCol = database.Collection("users")
	chaptersCol = database.Collection("chapters")
	progressCol = database.Collection("progress")

	log.Println("✅ Connected to MongoDB successfully")

	// Create indexes
	createIndexes()

	// Seed initial data
	seedData()

	return nil
}

// createIndexes creates necessary database indexes
func createIndexes() {
	ctx := context.Background()

	// User indexes
	usersCol.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "user_id", Value: 1}},
		Options: options.Index().SetUnique(true),
	})

	// Chapter indexes
	chaptersCol.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "chapter_id", Value: 1}},
		Options: options.Index().SetUnique(true),
	})

	// Progress indexes
	progressCol.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{
			{Key: "user_id", Value: 1},
			{Key: "chapter_id", Value: 1},
		},
		Options: options.Index().SetUnique(true),
	})

	log.Println("✅ Database indexes created")
}

// seedData seeds initial chapter data if not exists
func seedData() {
	ctx := context.Background()

	// Check if chapters already exist
	count, _ := chaptersCol.CountDocuments(ctx, bson.M{})
	if count > 0 {
		log.Println("📚 Chapters already exist, skipping seed")
		return
	}

	chapters := []Chapter{
		{
			ChapterID:   "chapter_1",
			Title:       "Introduction to Programming",
			Description: "Learn the fundamentals of programming and get started with your coding journey.",
			VideoURL:    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
			Duration:    596, // 9:56
			Order:       1,
			Quiz: Quiz{
				Questions: []Question{
					{
						ID:            "q1_1",
						QuestionText:  "What is a variable in programming?",
						Options:       []string{"A storage container for data", "A type of loop", "A function", "An operator"},
						CorrectAnswer: 0,
					},
					{
						ID:            "q1_2",
						QuestionText:  "Which of these is a programming language?",
						Options:       []string{"HTML", "CSS", "Python", "JSON"},
						CorrectAnswer: 2,
					},
					{
						ID:            "q1_3",
						QuestionText:  "What does IDE stand for?",
						Options:       []string{"Internet Development Environment", "Integrated Development Environment", "Internal Data Engine", "Interactive Design Editor"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q1_4",
						QuestionText:  "What is debugging?",
						Options:       []string{"Writing new code", "Finding and fixing errors", "Deleting old code", "Compiling code"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q1_5",
						QuestionText:  "What is an algorithm?",
						Options:       []string{"A programming language", "A step-by-step procedure to solve a problem", "A type of data", "A software tool"},
						CorrectAnswer: 1,
					},
				},
			},
		},
		{
			ChapterID:   "chapter_2",
			Title:       "Data Structures Basics",
			Description: "Understand essential data structures like arrays, lists, and how to use them effectively.",
			VideoURL:    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
			Duration:    653, // 10:53
			Order:       2,
			Quiz: Quiz{
				Questions: []Question{
					{
						ID:            "q2_1",
						QuestionText:  "What is an array?",
						Options:       []string{"A collection of elements of the same type", "A single value", "A function", "A class"},
						CorrectAnswer: 0,
					},
					{
						ID:            "q2_2",
						QuestionText:  "What is the time complexity of accessing an element in an array by index?",
						Options:       []string{"O(n)", "O(log n)", "O(1)", "O(n^2)"},
						CorrectAnswer: 2,
					},
					{
						ID:            "q2_3",
						QuestionText:  "What is a linked list?",
						Options:       []string{"An array of arrays", "A sequence of nodes where each node contains data and a reference to the next node", "A type of tree", "A sorting algorithm"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q2_4",
						QuestionText:  "Which data structure follows LIFO (Last In First Out)?",
						Options:       []string{"Queue", "Stack", "Array", "Linked List"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q2_5",
						QuestionText:  "What is the main advantage of a linked list over an array?",
						Options:       []string{"Faster access time", "Dynamic size", "Less memory usage", "Better cache performance"},
						CorrectAnswer: 1,
					},
				},
			},
		},
		{
			ChapterID:   "chapter_3",
			Title:       "Advanced Algorithms",
			Description: "Dive deep into sorting, searching, and optimization algorithms used in real-world applications.",
			VideoURL:    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
			Duration:    15, // 0:15
			Order:       3,
			Quiz: Quiz{
				Questions: []Question{
					{
						ID:            "q3_1",
						QuestionText:  "What is the average time complexity of Quick Sort?",
						Options:       []string{"O(n)", "O(n log n)", "O(n^2)", "O(log n)"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q3_2",
						QuestionText:  "Which algorithm is used for finding the shortest path in a graph?",
						Options:       []string{"Binary Search", "Merge Sort", "Dijkstra's Algorithm", "Bubble Sort"},
						CorrectAnswer: 2,
					},
					{
						ID:            "q3_3",
						QuestionText:  "What is dynamic programming?",
						Options:       []string{"A programming language", "A method for solving complex problems by breaking them into simpler subproblems", "A type of database", "A web framework"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q3_4",
						QuestionText:  "What does BFS stand for in graph traversal?",
						Options:       []string{"Best First Search", "Breadth First Search", "Binary File System", "Backward Forward Search"},
						CorrectAnswer: 1,
					},
					{
						ID:            "q3_5",
						QuestionText:  "Which sorting algorithm has the best worst-case time complexity?",
						Options:       []string{"Quick Sort", "Bubble Sort", "Merge Sort", "Selection Sort"},
						CorrectAnswer: 2,
					},
				},
			},
		},
	}

	var docs []interface{}
	for _, chapter := range chapters {
		docs = append(docs, chapter)
	}

	_, err := chaptersCol.InsertMany(ctx, docs)
	if err != nil {
		log.Printf("❌ Error seeding chapters: %v", err)
		return
	}

	log.Println("✅ Initial chapters seeded successfully")
}

// CloseDB closes the MongoDB connection
func CloseDB() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return client.Disconnect(ctx)
}

// ============================================================================
// API HANDLERS
// ============================================================================

// HealthCheck handler
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	response := ApiResponse{
		Success: true,
		Message: "Server is running",
		Data: map[string]string{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		},
	}
	sendJSON(w, http.StatusOK, response)
}

// Login handler - creates or retrieves user
func Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate input
	if strings.TrimSpace(req.UserID) == "" {
		sendError(w, http.StatusBadRequest, "User ID is required")
		return
	}

	if strings.TrimSpace(req.Name) == "" {
		req.Name = req.UserID // Use userID as name if not provided
	}

	ctx := context.Background()

	// Check if user exists
	var user User
	err := usersCol.FindOne(ctx, bson.M{"user_id": req.UserID}).Decode(&user)

	if err == mongo.ErrNoDocuments {
		// Create new user
		user = User{
			UserID:    req.UserID,
			Name:      req.Name,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}

		result, err := usersCol.InsertOne(ctx, user)
		if err != nil {
			sendError(w, http.StatusInternalServerError, "Failed to create user")
			return
		}
		user.ID = result.InsertedID.(primitive.ObjectID)
		log.Printf("✅ New user created: %s", req.UserID)
	} else if err != nil {
		sendError(w, http.StatusInternalServerError, "Database error")
		return
	} else {
		// Update last login time
		usersCol.UpdateOne(ctx, bson.M{"user_id": req.UserID}, bson.M{
			"$set": bson.M{"updated_at": time.Now()},
		})
		log.Printf("✅ User logged in: %s", req.UserID)
	}

	response := LoginResponse{
		Success: true,
		Message: "Login successful",
		User:    user,
	}
	sendJSON(w, http.StatusOK, response)
}

// GetChapters returns all chapters
func GetChapters(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()

	cursor, err := chaptersCol.Find(ctx, bson.M{}, options.Find().SetSort(bson.D{{Key: "order", Value: 1}}))
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to fetch chapters")
		return
	}
	defer cursor.Close(ctx)

	var chapters []Chapter
	if err := cursor.All(ctx, &chapters); err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to decode chapters")
		return
	}

	response := ApiResponse{
		Success: true,
		Message: "Chapters fetched successfully",
		Data:    chapters,
	}
	sendJSON(w, http.StatusOK, response)
}

// GetChapterByID returns a specific chapter
func GetChapterByID(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chapterID := vars["chapterId"]

	ctx := context.Background()

	var chapter Chapter
	err := chaptersCol.FindOne(ctx, bson.M{"chapter_id": chapterID}).Decode(&chapter)
	if err == mongo.ErrNoDocuments {
		sendError(w, http.StatusNotFound, "Chapter not found")
		return
	} else if err != nil {
		sendError(w, http.StatusInternalServerError, "Database error")
		return
	}

	response := ApiResponse{
		Success: true,
		Message: "Chapter fetched successfully",
		Data:    chapter,
	}
	sendJSON(w, http.StatusOK, response)
}

// GetUserProgress returns all progress for a user
func GetUserProgress(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["userId"]

	ctx := context.Background()

	cursor, err := progressCol.Find(ctx, bson.M{"user_id": userID})
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to fetch progress")
		return
	}
	defer cursor.Close(ctx)

	var progress []Progress
	if err := cursor.All(ctx, &progress); err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to decode progress")
		return
	}

	response := GetProgressResponse{
		Success:  true,
		Progress: progress,
	}
	sendJSON(w, http.StatusOK, response)
}

// GetChapterProgress returns progress for a specific chapter
func GetChapterProgress(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["userId"]
	chapterID := vars["chapterId"]

	ctx := context.Background()

	var progress Progress
	err := progressCol.FindOne(ctx, bson.M{
		"user_id":    userID,
		"chapter_id": chapterID,
	}).Decode(&progress)

	if err == mongo.ErrNoDocuments {
		// No progress yet - return empty progress
		progress = Progress{
			UserID:         userID,
			ChapterID:      chapterID,
			VideoProgress:  0,
			QuizProgress:   0,
			QuizAnswers:    []int{},
			LastAccessedAt: time.Now(),
			UpdatedAt:      time.Now(),
		}
	} else if err != nil {
		sendError(w, http.StatusInternalServerError, "Database error")
		return
	}

	response := ApiResponse{
		Success: true,
		Message: "Progress fetched successfully",
		Data:    progress,
	}
	sendJSON(w, http.StatusOK, response)
}

// UpdateVideoProgress updates video watching progress
func UpdateVideoProgress(w http.ResponseWriter, r *http.Request) {
	var req UpdateVideoProgressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate input
	if req.UserID == "" || req.ChapterID == "" {
		sendError(w, http.StatusBadRequest, "User ID and Chapter ID are required")
		return
	}

	if req.Progress < 0 {
		req.Progress = 0
	}

	ctx := context.Background()

	// Upsert progress
	filter := bson.M{
		"user_id":    req.UserID,
		"chapter_id": req.ChapterID,
	}

	update := bson.M{
		"$set": bson.M{
			"user_id":          req.UserID,
			"chapter_id":       req.ChapterID,
			"video_progress":   req.Progress,
			"video_completed":  req.Completed,
			"last_accessed_at": time.Now(),
			"updated_at":       time.Now(),
		},
		"$setOnInsert": bson.M{
			"quiz_progress":     0,
			"quiz_answers":      []int{},
			"quiz_completed":    false,
			"chapter_completed": false,
		},
	}

	opts := options.Update().SetUpsert(true)
	result, err := progressCol.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		log.Printf("❌ Error updating video progress: %v", err)
		sendError(w, http.StatusInternalServerError, "Failed to update progress")
		return
	}

	log.Printf("✅ Video progress updated: user=%s, chapter=%s, progress=%d, completed=%v",
		req.UserID, req.ChapterID, req.Progress, req.Completed)

	response := ApiResponse{
		Success: true,
		Message: "Video progress updated successfully",
		Data: map[string]interface{}{
			"matched":  result.MatchedCount,
			"modified": result.ModifiedCount,
			"upserted": result.UpsertedCount,
		},
	}
	sendJSON(w, http.StatusOK, response)
}

// UpdateQuizProgress updates quiz progress
func UpdateQuizProgress(w http.ResponseWriter, r *http.Request) {
	var req UpdateQuizProgressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate input
	if req.UserID == "" || req.ChapterID == "" {
		sendError(w, http.StatusBadRequest, "User ID and Chapter ID are required")
		return
	}

	ctx := context.Background()

	// Get current progress to update quiz answers array
	var currentProgress Progress
	err := progressCol.FindOne(ctx, bson.M{
		"user_id":    req.UserID,
		"chapter_id": req.ChapterID,
	}).Decode(&currentProgress)

	// Initialize quiz answers if needed
	if err == mongo.ErrNoDocuments || currentProgress.QuizAnswers == nil {
		currentProgress.QuizAnswers = make([]int, 5) // Assuming 5 questions per quiz
		for i := range currentProgress.QuizAnswers {
			currentProgress.QuizAnswers[i] = -1 // -1 means not answered
		}
	}

	// Update the answer for the current question
	if req.QuestionIndex >= 0 && req.QuestionIndex < len(currentProgress.QuizAnswers) {
		currentProgress.QuizAnswers[req.QuestionIndex] = req.Answer
	}

	// Check if chapter is completed (video + quiz both completed)
	chapterCompleted := currentProgress.VideoCompleted && req.Completed

	// Upsert progress
	filter := bson.M{
		"user_id":    req.UserID,
		"chapter_id": req.ChapterID,
	}

	update := bson.M{
		"$set": bson.M{
			"user_id":           req.UserID,
			"chapter_id":        req.ChapterID,
			"quiz_progress":     req.QuestionIndex,
			"quiz_answers":      currentProgress.QuizAnswers,
			"quiz_completed":    req.Completed,
			"chapter_completed": chapterCompleted,
			"last_accessed_at":  time.Now(),
			"updated_at":        time.Now(),
		},
		"$setOnInsert": bson.M{
			"video_progress":  0,
			"video_completed": false,
		},
	}

	opts := options.Update().SetUpsert(true)
	result, err := progressCol.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		log.Printf("❌ Error updating quiz progress: %v", err)
		sendError(w, http.StatusInternalServerError, "Failed to update progress")
		return
	}

	log.Printf("✅ Quiz progress updated: user=%s, chapter=%s, question=%d, completed=%v",
		req.UserID, req.ChapterID, req.QuestionIndex, req.Completed)

	response := ApiResponse{
		Success: true,
		Message: "Quiz progress updated successfully",
		Data: map[string]interface{}{
			"matched":  result.MatchedCount,
			"modified": result.ModifiedCount,
			"upserted": result.UpsertedCount,
		},
	}
	sendJSON(w, http.StatusOK, response)
}

// ResetProgress resets all progress for a user (useful for testing)
func ResetProgress(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["userId"]

	ctx := context.Background()

	result, err := progressCol.DeleteMany(ctx, bson.M{"user_id": userID})
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Failed to reset progress")
		return
	}

	log.Printf("✅ Progress reset for user: %s (deleted %d records)", userID, result.DeletedCount)

	response := ApiResponse{
		Success: true,
		Message: fmt.Sprintf("Progress reset successfully. Deleted %d records", result.DeletedCount),
	}
	sendJSON(w, http.StatusOK, response)
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func sendError(w http.ResponseWriter, status int, message string) {
	response := ApiResponse{
		Success: false,
		Message: message,
	}
	sendJSON(w, status, response)
}

// ============================================================================
// MAIN
// ============================================================================

func main() {
	// Initialize database
	if err := InitDB(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer CloseDB()

	// Create router
	router := mux.NewRouter()

	// API routes
	api := router.PathPrefix("/api").Subrouter()

	api.HandleFunc("/health", HealthCheck).Methods("GET")
	api.HandleFunc("/login", Login).Methods("POST")
	api.HandleFunc("/chapters", GetChapters).Methods("GET")
	api.HandleFunc("/chapters/{chapterId}", GetChapterByID).Methods("GET")
	api.HandleFunc("/progress/{userId}", GetUserProgress).Methods("GET")
	api.HandleFunc("/progress/{userId}/{chapterId}", GetChapterProgress).Methods("GET")
	api.HandleFunc("/progress/video", UpdateVideoProgress).Methods("POST")
	api.HandleFunc("/progress/quiz", UpdateQuizProgress).Methods("POST")
	api.HandleFunc("/progress/{userId}/reset", ResetProgress).Methods("DELETE")

	// CORS configuration
	corsHandler := handlers.CORS(
		handlers.AllowedOrigins([]string{"*"}),
		handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}),
		handlers.AllowedHeaders([]string{"Content-Type", "Authorization"}),
	)(router)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📡 API available at http://localhost:%s/api", port)
	log.Fatal(http.ListenAndServe(":"+port, corsHandler))
}
