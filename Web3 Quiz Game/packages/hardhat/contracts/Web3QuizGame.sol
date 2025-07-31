pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Web3QuizGame
 * @dev A decentralized quiz game with rewards and leaderboards
 */
contract Web3QuizGame is Ownable, ReentrancyGuard, Pausable {
    // Quiz structure
    struct Quiz {
        uint256 id;
        string title;
        string description;
        uint256 questionCount;
        uint256 timeLimit; // in seconds
        uint256 entryFee;
        uint256 rewardPool;
        bool isActive;
        address creator;
        uint256 createdAt;
    }
    
    // Question structure
    struct Question {
        uint256 quizId;
        string questionText;
        string[4] options;
        uint8 correctAnswer; // 0-3
        uint256 points;
    }
    
    // Player attempt structure
    struct QuizAttempt {
        address player;
        uint256 quizId;
        uint256 score;
        uint256 timeSpent;
        uint256 completedAt;
        bool isCompleted;
    }
    
    // Player stats
    struct PlayerStats {
        uint256 totalQuizzes;
        uint256 totalScore;
        uint256 highestScore;
        uint256 totalRewardsEarned;
        uint256 averageScore;
    }
    
    // State variables
    mapping(uint256 => Quiz) public quizzes;
    mapping(uint256 => Question[]) public quizQuestions;
    mapping(uint256 => mapping(address => QuizAttempt)) public attempts;
    mapping(uint256 => address[]) public quizParticipants;
    mapping(address => PlayerStats) public playerStats;
    mapping(uint256 => mapping(address => bool)) public hasAttempted;
    
    uint256 public quizCounter;
    uint256 public constant MIN_QUESTIONS = 3;
    uint256 public constant MAX_QUESTIONS = 20;
    uint256 public platformFeePercent = 5; // 5% platform fee
    
    // Events
    event QuizCreated(uint256 indexed quizId, address indexed creator, string title);
    event QuestionAdded(uint256 indexed quizId, uint256 questionIndex);
    event QuizStarted(uint256 indexed quizId, address indexed player);
    event QuizCompleted(uint256 indexed quizId, address indexed player, uint256 score);
    event RewardClaimed(uint256 indexed quizId, address indexed player, uint256 amount);
    event QuizActivated(uint256 indexed quizId);
    event QuizDeactivated(uint256 indexed quizId);
    
    // Custom errors
    error QuizNotFound();
    error QuizNotActive();
    error InsufficientFee();
    error AlreadyAttempted();
    error QuizNotCompleted();
    error InvalidQuestionCount();
    error InvalidAnswer();
    error QuizAlreadyStarted();
    error NoRewardToClaim();
    
    /**
     * @dev Create a new quiz
     * @param title Quiz title
     * @param description Quiz description
     * @param timeLimit Time limit in seconds
     * @param entryFee Entry fee in wei
     */
    function createQuiz(
        string memory title,
        string memory description,
        uint256 timeLimit,
        uint256 entryFee
    ) external returns (uint256) {
        uint256 quizId = quizCounter++;
        
        Quiz storage newQuiz = quizzes[quizId];
        newQuiz.id = quizId;
        newQuiz.title = title;
        newQuiz.description = description;
        newQuiz.timeLimit = timeLimit;
        newQuiz.entryFee = entryFee;
        newQuiz.creator = msg.sender;
        newQuiz.createdAt = block.timestamp;
        newQuiz.isActive = false;
        
        emit QuizCreated(quizId, msg.sender, title);
        return quizId;
    }
    
    /**
     * @dev Add a question to a quiz
     * @param quizId Quiz ID
     * @param questionText The question text
     * @param options Array of 4 answer options
     * @param correctAnswer Index of correct answer (0-3)
     * @param points Points awarded for correct answer
     */
    function addQuestion(
        uint256 quizId,
        string memory questionText,
        string[4] memory options,
        uint8 correctAnswer,
        uint256 points
    ) external {
        Quiz storage quiz = quizzes[quizId];
        if (quiz.creator == address(0)) revert QuizNotFound();
        require(msg.sender == quiz.creator || msg.sender == owner(), "Not authorized");
        require(correctAnswer < 4, "Invalid correct answer");
        require(quizQuestions[quizId].length < MAX_QUESTIONS, "Too many questions");
        
        Question memory newQuestion = Question({
            quizId: quizId,
            questionText: questionText,
            options: options,
            correctAnswer: correctAnswer,
            points: points
        });
        
        quizQuestions[quizId].push(newQuestion);
        quiz.questionCount = quizQuestions[quizId].length;
        
        emit QuestionAdded(quizId, quizQuestions[quizId].length - 1);
    }
    
    /**
     * @dev Activate a quiz (make it playable)
     * @param quizId Quiz ID to activate
     */
    function activateQuiz(uint256 quizId) external {
        Quiz storage quiz = quizzes[quizId];
        if (quiz.creator == address(0)) revert QuizNotFound();
        require(msg.sender == quiz.creator || msg.sender == owner(), "Not authorized");
        require(quiz.questionCount >= MIN_QUESTIONS, "Not enough questions");
        
        quiz.isActive = true;
        emit QuizActivated(quizId);
    }
    
    /**
     * @dev Start a quiz attempt
     * @param quizId Quiz ID to attempt
     */
    function startQuiz(uint256 quizId) external payable nonReentrant whenNotPaused {
        Quiz storage quiz = quizzes[quizId];
        if (quiz.creator == address(0)) revert QuizNotFound();
        if (!quiz.isActive) revert QuizNotActive();
        if (msg.value < quiz.entryFee) revert InsufficientFee();
        if (hasAttempted[quizId][msg.sender]) revert AlreadyAttempted();
        
        // Create attempt
        QuizAttempt storage attempt = attempts[quizId][msg.sender];
        attempt.player = msg.sender;
        attempt.quizId = quizId;
        attempt.isCompleted = false;
        
        hasAttempted[quizId][msg.sender] = true;
        quizParticipants[quizId].push(msg.sender);
        
        // Add to reward pool
        quiz.rewardPool += msg.value;
        
        emit QuizStarted(quizId, msg.sender);
    }
    
    /**
     * @dev Submit quiz answers and calculate score
     * @param quizId Quiz ID
     * @param answers Array of answer indices (0-3 for each question)
     * @param timeSpent Time spent on quiz in seconds
     */
    function submitQuiz(
        uint256 quizId,
        uint8[] memory answers,
        uint256 timeSpent
    ) external nonReentrant {
        Quiz storage quiz = quizzes[quizId];
        QuizAttempt storage attempt = attempts[quizId][msg.sender];
        
        if (quiz.creator == address(0)) revert QuizNotFound();
        if (!hasAttempted[quizId][msg.sender]) revert QuizNotFound();
        if (attempt.isCompleted) revert AlreadyAttempted();
        require(answers.length == quiz.questionCount, "Invalid answer count");
        require(timeSpent <= quiz.timeLimit, "Time limit exceeded");
        
        // Calculate score
        uint256 totalScore = 0;
        Question[] storage questions = quizQuestions[quizId];
        
        for (uint256 i = 0; i < answers.length; i++) {
            if (answers[i] > 3) revert InvalidAnswer();
            if (answers[i] == questions[i].correctAnswer) {
                totalScore += questions[i].points;
            }
        }
        
        // Update attempt
        attempt.score = totalScore;
        attempt.timeSpent = timeSpent;
        attempt.completedAt = block.timestamp;
        attempt.isCompleted = true;
        
        // Update player stats
        PlayerStats storage stats = playerStats[msg.sender];
        stats.totalQuizzes++;
        stats.totalScore += totalScore;
        if (totalScore > stats.highestScore) {
            stats.highestScore = totalScore;
        }
        stats.averageScore = stats.totalScore / stats.totalQuizzes;
        
        emit QuizCompleted(quizId, msg.sender, totalScore);
    }
    
    /**
     * @dev Claim rewards based on performance
     * @param quizId Quiz ID to claim rewards from
     */
    function claimReward(uint256 quizId) external nonReentrant {
        Quiz storage quiz = quizzes[quizId];
        QuizAttempt storage attempt = attempts[quizId][msg.sender];
        
        if (!attempt.isCompleted) revert QuizNotCompleted();
        require(attempt.score > 0, "No score to claim reward");
        
        // Calculate reward based on performance and pool
        uint256 totalParticipants = quizParticipants[quizId].length;
        uint256 reward = calculateReward(quizId, msg.sender, totalParticipants);
        
        if (reward == 0) revert NoRewardToClaim();
        
        // Platform fee
        uint256 platformFee = (reward * platformFeePercent) / 100;
        uint256 playerReward = reward - platformFee;
        
        // Update stats
        playerStats[msg.sender].totalRewardsEarned += playerReward;
        
        // Transfer rewards
        payable(msg.sender).transfer(playerReward);
        payable(owner()).transfer(platformFee);
        
        emit RewardClaimed(quizId, msg.sender, playerReward);
    }
    
    /**
     * @dev Calculate reward for a player
     * @param quizId Quiz ID
     * @param player Player address
     * @param totalParticipants Total number of participants
     * @return reward Calculated reward amount
     */
    function calculateReward(
        uint256 quizId,
        address player,
        uint256 totalParticipants
    ) internal view returns (uint256 reward) {
        Quiz storage quiz = quizzes[quizId];
        QuizAttempt storage attempt = attempts[quizId][player];
        
        if (totalParticipants == 0 || attempt.score == 0) return 0;
        
        // Simple reward calculation: score percentage * pool share
        uint256 maxPossibleScore = 0;
        Question[] storage questions = quizQuestions[quizId];
        
        for (uint256 i = 0; i < questions.length; i++) {
            maxPossibleScore += questions[i].points;
        }
        
        if (maxPossibleScore == 0) return 0;
        
        uint256 scorePercentage = (attempt.score * 100) / maxPossibleScore;
        uint256 baseReward = quiz.rewardPool / totalParticipants;
        
        // Bonus for high performers
        if (scorePercentage >= 90) {
            reward = baseReward * 2;
        } else if (scorePercentage >= 70) {
            reward = (baseReward * 150) / 100;
        } else if (scorePercentage >= 50) {
            reward = baseReward;
        } else {
            reward = baseReward / 2;
        }
        
        // Ensure we don't exceed available pool
        if (reward > quiz.rewardPool) {
            reward = quiz.rewardPool;
        }
    }
    
    // View functions
    
    /**
     * @dev Get quiz information
     * @param quizId Quiz ID
     * @return Quiz struct data
     */
    function getQuiz(uint256 quizId) external view returns (Quiz memory) {
        return quizzes[quizId];
    }
    
    /**
     * @dev Get quiz questions (without correct answers)
     * @param quizId Quiz ID
     * @return questions Array of questions with options but no correct answers
     */
    function getQuizQuestions(uint256 quizId) external view returns (Question[] memory questions) {
        questions = quizQuestions[quizId];
        
        // Remove correct answers for security
        for (uint256 i = 0; i < questions.length; i++) {
            questions[i].correctAnswer = 0; // Reset to hide answer
        }
    }
    
    /**
     * @dev Get player's quiz attempt
     * @param quizId Quiz ID
     * @param player Player address
     * @return QuizAttempt struct data
     */
    function getAttempt(uint256 quizId, address player) external view returns (QuizAttempt memory) {
        return attempts[quizId][player];
    }
    
    /**
     * @dev Get leaderboard for a quiz
     * @param quizId Quiz ID
     * @return players Array of player addresses sorted by score
     * @return scores Array of corresponding scores
     */
    function getLeaderboard(uint256 quizId) external view returns (
        address[] memory players,
        uint256[] memory scores
    ) {
        address[] memory participants = quizParticipants[quizId];
        uint256 completedCount = 0;
        
        // Count completed attempts
        for (uint256 i = 0; i < participants.length; i++) {
            if (attempts[quizId][participants[i]].isCompleted) {
                completedCount++;
            }
        }
        
        players = new address[](completedCount);
        scores = new uint256[](completedCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            if (attempts[quizId][participants[i]].isCompleted) {
                players[index] = participants[i];
                scores[index] = attempts[quizId][participants[i]].score;
                index++;
            }
        }
        
        // Simple bubble sort (for small arrays)
        for (uint256 i = 0; i < scores.length; i++) {
            for (uint256 j = i + 1; j < scores.length; j++) {
                if (scores[i] < scores[j]) {
                    // Swap scores
                    uint256 tempScore = scores[i];
                    scores[i] = scores[j];
                    scores[j] = tempScore;
                    
                    // Swap players
                    address tempPlayer = players[i];
                    players[i] = players[j];
                    players[j] = tempPlayer;
                }
            }
        }
    }
    
    /**
     * @dev Get player statistics
     * @param player Player address
     * @return PlayerStats struct data
     */
    function getPlayerStats(address player) external view returns (PlayerStats memory) {
        return playerStats[player];
    }
    
    // Owner functions
    
    /**
     * @dev Set platform fee percentage
     * @param feePercent New fee percentage (0-100)
     */
    function setPlatformFee(uint256 feePercent) external onlyOwner {
        require(feePercent <= 20, "Fee too high");
        platformFeePercent = feePercent;
    }
    
    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency withdraw (only if paused)
     */
    function emergencyWithdraw() external onlyOwner {
        require(paused(), "Contract not paused");
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Get total number of quizzes
     * @return Total quiz count
     */
    function getTotalQuizzes() external view returns (uint256) {
        return quizCounter;
    }
}