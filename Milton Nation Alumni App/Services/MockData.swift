import Foundation

enum MockData {

    // MARK: - Current User
    static let currentUser: User = {
        var u = User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            email: "alex.demo@example.com",
            phone: "(555) 123-4567",
            fullName: "Alex Demo",
            username: "recovery_warrior",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -1442, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -1440, to: Date())!,
            recoveryProgram: "Milton Recovery Residential",
            role: .alumni,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 0,
            lastLogin: Date(),
            lastPointsAwarded: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1442, to: Date())!,
            updatedAt: Date()
        )
        u.facility = .florida
        return u
    }()

    // MARK: - Staff
    static let caseManager = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        email: "dana.case@example.com",
        phone: "(555) 234-5678",
        fullName: "Dana Case",
        username: "dana_cm",
        profilePhotoURL: nil,
        sobrietyDate: Date(),
        dischargeDate: Date(),
        recoveryProgram: "",
        role: .caseManager,
        status: .active,
        mfaMethod: .email,
        totalPoints: 0,
        lastLogin: Date(),
        lastPointsAwarded: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let therapist = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        email: "dr.nova@example.com",
        phone: "(555) 345-6789",
        fullName: "Dr. Robin Nova",
        username: "dr_nova",
        profilePhotoURL: nil,
        sobrietyDate: Date(),
        dischargeDate: Date(),
        recoveryProgram: "",
        role: .therapist,
        status: .active,
        mfaMethod: .totp,
        totalPoints: 0,
        lastLogin: Date(),
        lastPointsAwarded: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let counselor = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
        email: "casey.guide@example.com",
        phone: "(555) 456-7890",
        fullName: "Casey Guide",
        username: "casey_counselor",
        profilePhotoURL: nil,
        sobrietyDate: Date(),
        dischargeDate: Date(),
        recoveryProgram: "",
        role: .counselor,
        status: .active,
        mfaMethod: .email,
        totalPoints: 0,
        lastLogin: Date(),
        lastPointsAwarded: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Alumni Roster (for Admin Dashboard)
    static let alumniRoster: [User] = [
        currentUser,
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
            email: "jordan.test@example.com",
            phone: "(555) 567-8901",
            fullName: "Jordan Test",
            username: "phoenix_rising",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -365, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -360, to: Date())!,
            recoveryProgram: "Milton Recovery Residential",
            role: .alumni,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 620,
            lastLogin: Calendar.current.date(byAdding: .hour, value: -3, to: Date()),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -365, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            email: "taylor.sample@example.com",
            phone: "(555) 678-9012",
            fullName: "Taylor Sample",
            username: "grateful_heart",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -85, to: Date())!,
            recoveryProgram: "Milton Recovery IOP",
            role: .alumni,
            status: .active,
            mfaMethod: .email,
            totalPoints: 310,
            lastLogin: Calendar.current.date(byAdding: .hour, value: -12, to: Date()),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
            email: "morgan.mock@example.com",
            phone: "(555) 789-0123",
            fullName: "Morgan Mock",
            username: "stronger_today",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -540, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -535, to: Date())!,
            recoveryProgram: "Milton Recovery Residential",
            role: .alumni,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 950,
            lastLogin: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -540, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!,
            email: "riley.placeholder@example.com",
            phone: "(555) 890-1234",
            fullName: "Riley Placeholder",
            username: "helping_hand",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -18, to: Date())!,
            recoveryProgram: "Milton Recovery PHP",
            role: .alumni,
            status: .active,
            mfaMethod: .email,
            totalPoints: 85,
            lastLogin: Date(),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!,
            email: "sam.fixture@example.com",
            phone: "(555) 901-2345",
            fullName: "Sam Fixture",
            username: "new_beginnings",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -730, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -725, to: Date())!,
            recoveryProgram: "Milton Recovery Residential",
            role: .alumni,
            status: .active,
            mfaMethod: .totp,
            totalPoints: 1200,
            lastLogin: Calendar.current.date(byAdding: .hour, value: -8, to: Date()),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -730, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000025")!,
            email: "avery.testdata@example.com",
            phone: "(555) 012-3456",
            fullName: "Avery Testdata",
            username: "one_day_at_a_time",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -40, to: Date())!,
            recoveryProgram: "Milton Recovery IOP",
            role: .alumni,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 155,
            lastLogin: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            lastPointsAwarded: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
            updatedAt: Date()
        ),
    ]

    // MARK: - Staff Assignments
    static let staffAssignments: [StaffAssignment] = [
        StaffAssignment(id: UUID(), userId: currentUser.id, staffId: caseManager.id, roleType: .caseManager, assignedAt: Date()),
        StaffAssignment(id: UUID(), userId: currentUser.id, staffId: therapist.id, roleType: .therapist, assignedAt: Date()),
        StaffAssignment(id: UUID(), userId: currentUser.id, staffId: counselor.id, roleType: .counselor, assignedAt: Date()),
    ]

    // MARK: - Daily Quotes (100+)
    static let quotes: [DailyQuote] = [
        // Classic recovery quotes
        DailyQuote(id: UUID(), text: "Fall seven times, stand up eight.", attribution: "Japanese Proverb", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The only way out is through.", attribution: "Robert Frost", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Recovery is not a race. You don't have to feel guilty if it takes you longer than you thought it would.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "One day at a time.", attribution: "AA Motto", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You are not your addiction. You are the person who overcame it.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Strength doesn't come from what you can do. It comes from overcoming the things you once thought you couldn't.", attribution: "Rikki Rogers", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", attribution: "Nelson Mandela", scheduledDate: nil),
        // Courage & strength
        DailyQuote(id: UUID(), text: "Courage isn't having the strength to go on — it is going on when you don't have strength.", attribution: "Napoleon Bonaparte", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "It does not matter how slowly you go as long as you do not stop.", attribution: "Confucius", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You may have to fight a battle more than once to win it.", attribution: "Margaret Thatcher", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", attribution: "Ralph Waldo Emerson", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The secret of getting ahead is getting started.", attribution: "Mark Twain", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Believe you can and you're halfway there.", attribution: "Theodore Roosevelt", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Out of suffering have emerged the strongest souls.", attribution: "Kahlil Gibran", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Though no one can go back and make a brand new start, anyone can start from now and make a brand new ending.", attribution: "Carl Bard", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Rock bottom became the solid foundation on which I rebuilt my life.", attribution: "J.K. Rowling", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Every moment is a fresh beginning.", attribution: "T.S. Eliot", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The wound is the place where the Light enters you.", attribution: "Rumi", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Hardships often prepare ordinary people for an extraordinary destiny.", attribution: "C.S. Lewis", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The only person you are destined to become is the person you decide to be.", attribution: "Ralph Waldo Emerson", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Don't let yesterday take up too much of today.", attribution: "Will Rogers", scheduledDate: nil),
        // Recovery-specific
        DailyQuote(id: UUID(), text: "Recovery is an acceptance that your life is in shambles and you have to change it.", attribution: "Jamie Lee Curtis", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "People often say that motivation doesn't last. Neither does bathing — that's why we recommend it daily.", attribution: "Zig Ziglar", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Sobriety was the greatest gift I ever gave myself.", attribution: "Rob Lowe", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The first step toward change is awareness. The second step is acceptance.", attribution: "Nathaniel Branden", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "We cannot solve our problems with the same thinking we used when we created them.", attribution: "Albert Einstein", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Sometimes the smallest step in the right direction ends up being the biggest step of your life.", attribution: "Naeem Callaway", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Recovery is about progression, not perfection.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You don't have to see the whole staircase, just take the first step.", attribution: "Martin Luther King Jr.", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", attribution: "Winston Churchill", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The best time to plant a tree was 20 years ago. The second best time is now.", attribution: "Chinese Proverb", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Addiction begins with the hope that something out there can instantly fill up the emptiness inside.", attribution: "Jean Kilbourne", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "When everything seems to be going against you, remember that the airplane takes off against the wind, not with it.", attribution: "Henry Ford", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "I understood myself only after I destroyed myself. And only in the process of fixing myself, did I know who I really was.", attribution: "Sade Andria Zabala", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "In the middle of difficulty lies opportunity.", attribution: "Albert Einstein", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Recovery is something you have to work on every single day, and it's something that doesn't get a day off.", attribution: "Demi Lovato", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "There is no greater agony than bearing an untold story inside you.", attribution: "Maya Angelou", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Be gentle with yourself. You're doing the best you can.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The only impossible journey is the one you never begin.", attribution: "Tony Robbins", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Your present circumstances don't determine where you can go; they merely determine where you start.", attribution: "Nido Qubein", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You were never created to live depressed, defeated, guilty, condemned, ashamed or unworthy.", attribution: "Joel Osteen", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Let go of who you think you're supposed to be; embrace who you are.", attribution: "Brene Brown", scheduledDate: nil),
        // Hope & resilience
        DailyQuote(id: UUID(), text: "This too shall pass.", attribution: "Persian Proverb", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Healing is not linear.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Stars can't shine without darkness.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You are allowed to be both a masterpiece and a work in progress simultaneously.", attribution: "Sophia Bush", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "What we achieve inwardly will change outer reality.", attribution: "Plutarch", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "I am not what happened to me. I am what I choose to become.", attribution: "Carl Jung", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "New beginnings are often disguised as painful endings.", attribution: "Lao Tzu", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The human capacity for burden is like bamboo — far more flexible than you'd ever believe at first glance.", attribution: "Jodi Picoult", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "With the new day comes new strength and new thoughts.", attribution: "Eleanor Roosevelt", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Life doesn't get easier or more forgiving; we get stronger and more resilient.", attribution: "Steve Maraboli", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "It's not whether you get knocked down, it's whether you get up.", attribution: "Vince Lombardi", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The comeback is always stronger than the setback.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Turn your wounds into wisdom.", attribution: "Oprah Winfrey", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Almost everything will work again if you unplug it for a few minutes, including you.", attribution: "Anne Lamott", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Act as if what you do makes a difference. It does.", attribution: "William James", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "I am thankful for my struggle because without it I wouldn't have stumbled across my strength.", attribution: "Alex Elle", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Nothing is impossible. The word itself says I'm possible.", attribution: "Audrey Hepburn", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Change your thoughts and you change your world.", attribution: "Norman Vincent Peale", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Our greatest glory is not in never failing, but in rising every time we fail.", attribution: "Confucius", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The best way to predict your future is to create it.", attribution: "Abraham Lincoln", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "No matter how hard the past, you can always begin again.", attribution: "Buddha", scheduledDate: nil),
        // Self-care & growth
        DailyQuote(id: UUID(), text: "Caring for your body, mind, and spirit is your greatest and grandest responsibility.", attribution: "Deepak Chopra", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Be patient with yourself. Self-growth is tender; it's holy ground.", attribution: "Stephen Covey", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You can't go back and change the beginning, but you can start where you are and change the ending.", attribution: "C.S. Lewis", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Happiness is not something ready-made. It comes from your own actions.", attribution: "Dalai Lama", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Progress, not perfection.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Every day in every way, I'm getting better and better.", attribution: "Emile Coue", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "It is during our darkest moments that we must focus to see the light.", attribution: "Aristotle", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Keep your face always toward the sunshine — and shadows will fall behind you.", attribution: "Walt Whitman", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "We are what we repeatedly do. Excellence then, is not an act, but a habit.", attribution: "Aristotle", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference.", attribution: "Serenity Prayer", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Every morning we are born again. What we do today matters most.", attribution: "Buddha", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You are braver than you believe, stronger than you seem, and smarter than you think.", attribution: "A.A. Milne", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Your life does not get better by chance, it gets better by change.", attribution: "Jim Rohn", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "If you're going through hell, keep going.", attribution: "Winston Churchill", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Don't count the days; make the days count.", attribution: "Muhammad Ali", scheduledDate: nil),
        // Community & connection
        DailyQuote(id: UUID(), text: "Alone we can do so little; together we can do so much.", attribution: "Helen Keller", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Surround yourself with only people who are going to lift you higher.", attribution: "Oprah Winfrey", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "There is no exercise better for the heart than reaching down and lifting people up.", attribution: "John Holmes", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Connection is the opposite of addiction.", attribution: "Johann Hari", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "We rise by lifting others.", attribution: "Robert Ingersoll", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Asking for help is not a sign of weakness. It's a sign of strength.", attribution: "Barack Obama", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "No one saves us but ourselves. No one can and no one may. We ourselves must walk the path.", attribution: "Buddha", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "In the midst of winter, I found there was, within me, an invincible summer.", attribution: "Albert Camus", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Never be ashamed of a scar. It simply means you were stronger than whatever tried to hurt you.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "When you can't control what's happening, challenge yourself to control the way you respond.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You have within you right now, everything you need to deal with whatever the world can throw at you.", attribution: "Brian Tracy", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "It always seems impossible until it's done.", attribution: "Nelson Mandela", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The struggle you're in today is developing the strength you need for tomorrow.", attribution: "Robert Tew", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Just because you're struggling doesn't mean you're failing. Every great success requires some kind of struggle.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Hope is being able to see that there is light despite all of the darkness.", attribution: "Desmond Tutu", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "A journey of a thousand miles begins with a single step.", attribution: "Lao Tzu", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "The greatest weapon against stress is our ability to choose one thought over another.", attribution: "William James", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Gratitude turns what we have into enough.", attribution: "Aesop", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "You don't drown by falling in the water; you drown by staying there.", attribution: "Edwin Louis Cole", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "What is coming is better than what is gone.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "There are far, far better things ahead than any we leave behind.", attribution: "C.S. Lewis", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Getting sober was the single bravest thing I've ever done and will ever do in my life.", attribution: "Jamie Lee Curtis", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "When we are no longer able to change a situation, we are challenged to change ourselves.", attribution: "Viktor Frankl", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Letting go doesn't mean giving up, but rather accepting that there are things that cannot be.", attribution: "Unknown", scheduledDate: nil),
        DailyQuote(id: UUID(), text: "Every day may not be good, but there is something good in every day.", attribution: "Alice Morse Earle", scheduledDate: nil),
    ]

    // MARK: - Community Posts (using anonymous usernames)
    static let posts: [CommunityPost] = [
        CommunityPost(
            id: UUID(), userId: currentUser.id, userName: "recovery_warrior",
            userPhotoURL: nil, category: .wins,
            content: "Just celebrated another milestone in my recovery! The journey isn't always easy, but it's always worth it. Grateful for the Milton community.",
            mediaURL: nil, mediaType: nil, status: .approved, isPinned: true,
            likesCount: 32, commentsCount: 12, isLikedByCurrentUser: false,
            createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
            approvedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        ),
        CommunityPost(
            id: UUID(), userId: UUID(), userName: "phoenix_rising",
            userPhotoURL: nil, category: .wins,
            content: "Just hit 6 months clean today! Never thought I'd make it this far. Thank you all for the support. This community has been my rock.",
            mediaURL: "mock://media/celebration-photo.jpg", mediaType: .image, status: .approved, isPinned: false,
            likesCount: 24, commentsCount: 8, isLikedByCurrentUser: true,
            createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            approvedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        ),
        CommunityPost(
            id: UUID(), userId: UUID(), userName: "grateful_heart",
            userPhotoURL: nil, category: .gratitude,
            content: "Grateful for my sponsor and everyone at Milton who believed in me when I couldn't believe in myself. Recovery is possible.",
            mediaURL: nil, mediaType: nil, status: .approved, isPinned: false,
            likesCount: 18, commentsCount: 5, isLikedByCurrentUser: false,
            createdAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
            approvedAt: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!
        ),
        CommunityPost(
            id: UUID(), userId: UUID(), userName: "stronger_today",
            userPhotoURL: nil, category: .struggles,
            content: "Having a tough day today. Cravings are strong but I'm reaching out instead of giving in. Any words of encouragement?",
            mediaURL: "mock://media/journal-entry.jpg", mediaType: .image, status: .pending, isPinned: false,
            likesCount: 31, commentsCount: 15, isLikedByCurrentUser: true,
            createdAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
            approvedAt: nil
        ),
        CommunityPost(
            id: UUID(), userId: UUID(), userName: "helping_hand",
            userPhotoURL: nil, category: .support,
            content: "If anyone needs someone to talk to tonight, my DMs are open. We're all in this together. You don't have to do it alone.",
            mediaURL: nil, mediaType: nil, status: .approved, isPinned: false,
            likesCount: 42, commentsCount: 3, isLikedByCurrentUser: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            approvedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
    ]

    // MARK: - Meetings (with coordinates for MapKit)
    static let meetings: [Meeting] = [
        Meeting(
            id: UUID(), title: "Weekly Alumni Check-In",
            description: "Our regular weekly meeting for all Milton alumni. Share your wins, struggles, and support each other.",
            meetingType: .hybrid,
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            startTime: createTime(hour: 18, minute: 0),
            endTime: createTime(hour: 19, minute: 30),
            locationAddress: "Milton Recovery Center, 123 Recovery Lane, Suite 200",
            locationLat: 25.7617,
            locationLng: -80.1918,
            virtualLink: "https://zoom.us/j/1234567890",
            isRecurring: true, recurrencePattern: .weekly,
            recurrenceEndDate: nil, parentMeetingId: nil,
            createdBy: caseManager.id, createdAt: Date(),
            rsvpUserIds: [alumniRoster[0].id, alumniRoster[1].id, alumniRoster[2].id, alumniRoster[4].id]
        ),
        Meeting(
            id: UUID(), title: "Mindfulness & Meditation",
            description: "Guided meditation session focused on managing cravings and stress.",
            meetingType: .virtual,
            date: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
            startTime: createTime(hour: 10, minute: 0),
            endTime: createTime(hour: 11, minute: 0),
            locationAddress: nil,
            locationLat: nil,
            locationLng: nil,
            virtualLink: "https://meet.google.com/abc-defg-hij",
            isRecurring: true, recurrencePattern: .weekly,
            recurrenceEndDate: nil, parentMeetingId: nil,
            createdBy: therapist.id, createdAt: Date()
        ),
        Meeting(
            id: UUID(), title: "Family & Friends Support Group",
            description: "Open meeting for alumni and their loved ones.",
            meetingType: .inPerson,
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            startTime: createTime(hour: 14, minute: 0),
            endTime: createTime(hour: 15, minute: 30),
            locationAddress: "Milton Community Hall, 456 Hope Street",
            locationLat: 25.7839,
            locationLng: -80.2102,
            virtualLink: nil,
            isRecurring: true, recurrencePattern: .monthly,
            recurrenceEndDate: nil, parentMeetingId: nil,
            createdBy: caseManager.id, createdAt: Date(),
            rsvpUserIds: [alumniRoster[0].id, alumniRoster[3].id, alumniRoster[5].id]
        ),
        Meeting(
            id: UUID(), title: "Relapse Prevention Workshop",
            description: "Interactive workshop on identifying triggers and building coping strategies.",
            meetingType: .inPerson,
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            startTime: createTime(hour: 15, minute: 0),
            endTime: createTime(hour: 16, minute: 30),
            locationAddress: "Milton Recovery Center, 123 Recovery Lane, Room 105",
            locationLat: 25.7620,
            locationLng: -80.1922,
            virtualLink: nil,
            isRecurring: true, recurrencePattern: .biweekly,
            recurrenceEndDate: nil, parentMeetingId: nil,
            createdBy: counselor.id, createdAt: Date()
        ),
        Meeting(
            id: UUID(), title: "Young Adults Recovery Group",
            description: "A safe space for young adults (18-30) in recovery to share experiences.",
            meetingType: .hybrid,
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            startTime: createTime(hour: 19, minute: 0),
            endTime: createTime(hour: 20, minute: 30),
            locationAddress: "Coral Gables Community Center, 2700 Salzedo St",
            locationLat: 25.7497,
            locationLng: -80.2564,
            virtualLink: "https://zoom.us/j/9876543210",
            isRecurring: true, recurrencePattern: .weekly,
            recurrenceEndDate: nil, parentMeetingId: nil,
            createdBy: caseManager.id, createdAt: Date()
        ),
    ]

    // MARK: - Conversations & Messages
    static let conversations: [Conversation] = [
        Conversation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            userId: currentUser.id, staffId: caseManager.id,
            staffName: "Dana Case", staffRole: .caseManager,
            staffPhotoURL: nil,
            lastMessage: "Great progress this week! Keep it up.",
            lastMessageAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            unreadCount: 1, createdAt: Date()
        ),
        Conversation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userId: currentUser.id, staffId: therapist.id,
            staffName: "Dr. Robin Nova", staffRole: .therapist,
            staffPhotoURL: nil,
            lastMessage: "See you at our next session on Thursday.",
            lastMessageAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            unreadCount: 0, createdAt: Date()
        ),
        Conversation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            userId: currentUser.id, staffId: counselor.id,
            staffName: "Casey Guide", staffRole: .counselor,
            staffPhotoURL: nil,
            lastMessage: nil,
            lastMessageAt: nil,
            unreadCount: 0, createdAt: Date()
        ),
    ]

    static let sampleMessages: [ChatMessage] = [
        ChatMessage(id: UUID(), conversationId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                    senderId: caseManager.id, messageType: .text,
                    content: "Hi! How are you doing this week?",
                    createdAt: Calendar.current.date(byAdding: .hour, value: -48, to: Date())!,
                    isFromCurrentUser: false),
        ChatMessage(id: UUID(), conversationId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                    senderId: currentUser.id, messageType: .text,
                    content: "Doing really well! Had some tough moments but stayed strong.",
                    createdAt: Calendar.current.date(byAdding: .hour, value: -47, to: Date())!,
                    isFromCurrentUser: true),
        ChatMessage(id: UUID(), conversationId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                    senderId: caseManager.id, messageType: .text,
                    content: "That's wonderful to hear. What helped you get through the tough moments?",
                    createdAt: Calendar.current.date(byAdding: .hour, value: -46, to: Date())!,
                    isFromCurrentUser: false),
        ChatMessage(id: UUID(), conversationId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                    senderId: currentUser.id, messageType: .text,
                    content: "I used the breathing exercises from our last session and called my sponsor. It really helped.",
                    createdAt: Calendar.current.date(byAdding: .hour, value: -45, to: Date())!,
                    isFromCurrentUser: true),
        ChatMessage(id: UUID(), conversationId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                    senderId: caseManager.id, messageType: .text,
                    content: "Great progress this week! Keep it up.",
                    createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                    isFromCurrentUser: false),
    ]

    // MARK: - Badges (scaled to 5,000 max)
    static let badges: [Badge] = [
        Badge(id: UUID(), name: "Seedling", description: "You're growing! Earned at 100 points.", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
        Badge(id: UUID(), name: "Sprout", description: "Reaching new heights! Earned at 250 points.", emoji: "🌿", pointsRequired: 250, sortOrder: 2),
        Badge(id: UUID(), name: "Bloom", description: "Starting to blossom! Earned at 500 points.", emoji: "🌸", pointsRequired: 500, sortOrder: 3),
        Badge(id: UUID(), name: "Tree", description: "Standing tall! Earned at 750 points.", emoji: "🌳", pointsRequired: 750, sortOrder: 4),
        Badge(id: UUID(), name: "Oak", description: "Mighty and unshakeable! Earned at 1,000 points.", emoji: "🌲", pointsRequired: 1000, sortOrder: 5),
        Badge(id: UUID(), name: "Mountain", description: "Reaching the summit! Earned at 1,500 points.", emoji: "⛰️", pointsRequired: 1500, sortOrder: 6),
        Badge(id: UUID(), name: "Star", description: "Shining bright! Earned at 2,000 points.", emoji: "⭐", pointsRequired: 2000, sortOrder: 7),
        Badge(id: UUID(), name: "Fire", description: "Unstoppable! Earned at 2,500 points.", emoji: "🔥", pointsRequired: 2500, sortOrder: 8),
        Badge(id: UUID(), name: "Diamond", description: "Rare and resilient! Earned at 3,000 points.", emoji: "💎", pointsRequired: 3000, sortOrder: 9),
        Badge(id: UUID(), name: "Crown", description: "Royally committed! Earned at 3,500 points.", emoji: "👑", pointsRequired: 3500, sortOrder: 10),
        Badge(id: UUID(), name: "Phoenix", description: "Rising from the ashes! Earned at 4,000 points.", emoji: "🦅", pointsRequired: 4000, sortOrder: 11),
        Badge(id: UUID(), name: "Legend", description: "A true legend of recovery! Earned at 5,000 points.", emoji: "🏆", pointsRequired: 5000, sortOrder: 12),
    ]

    // MARK: - Crisis Resources
    static let crisisResources: [CrisisResource] = [
        CrisisResource(name: "988 Suicide & Crisis Lifeline", phoneNumber: "988", description: "24/7 crisis support", isEmergency: true),
        CrisisResource(name: "SAMHSA Helpline", phoneNumber: "1-800-662-4357", description: "Free, confidential, 24/7 treatment referral", isEmergency: true),
        CrisisResource(name: "Crisis Text Line", phoneNumber: "741741", description: "Text HOME to 741741", isEmergency: true, contactType: .sms),
    ]

    // MARK: - Company Contacts
    static let companyContacts: [CompanyContact] = [
        CompanyContact(name: "Milton Team", phoneNumber: "(844) 975-4673", role: "General Inquiries"),
        CompanyContact(name: "After-Hours Support", phoneNumber: "(844) 975-4673", role: "24/7 Support Line"),
    ]

    // MARK: - Announcements
    static var announcements: [Announcement] = [
        Announcement(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000A01")!,
            title: "Welcome to Milton Alumni!",
            description: "We're excited to launch our new alumni app. Stay connected, share your journey, and support each other. Check back here for the latest updates from the Milton team.",
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        ),
        Announcement(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000A02")!,
            title: "New Weekly Mindfulness Group",
            description: "Join our new guided mindfulness group every Thursday at 10 AM. Virtual and in-person options available. Sign up through the Meetings tab.",
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
    ]

    // MARK: - Admin & Super Admin Test Users
    static let adminUser: User = {
        var u = User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000A10")!,
            email: "admin@milton.com",
            phone: "(555) 500-1000",
            fullName: "Admin User",
            username: "admin_user",
            profilePhotoURL: nil,
            sobrietyDate: Date(),
            dischargeDate: Date(),
            recoveryProgram: "",
            role: .admin,
            status: .active,
            mfaMethod: .email,
            totalPoints: 0,
            lastLogin: Date(),
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        u.adminFacility = .florida
        return u
    }()

    static let superAdminUser = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000A11")!,
        email: "super@milton.com",
        phone: "(555) 500-2000",
        fullName: "Super Admin",
        username: "super_admin",
        profilePhotoURL: nil,
        sobrietyDate: Date(),
        dischargeDate: Date(),
        recoveryProgram: "",
        role: .superAdmin,
        status: .active,
        mfaMethod: .totp,
        totalPoints: 0,
        lastLogin: Date(),
        lastPointsAwarded: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Helpers
    private static func createTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
