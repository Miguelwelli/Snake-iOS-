import SwiftUI
import UIKit
import Combine

// MARK: - Modelo do jogo

/// Toda a lógica do jogo roda no ator principal, então a interface e o timer
/// nunca competem por estado. Sem dependências externas.
@MainActor
final class SnakeGame: ObservableObject {
    // Configuração.
    static let cellCount = 20          // células por lado do tabuleiro (qualquer iPhone)
    static let baseInterval = 0.16     // segundos por tick na velocidade 1
    static let speedStep = 0.014       // subtraído do intervalo a cada nível de velocidade
    static let minInterval = 0.06      // tick mais rápido possível

    // Estado publicado.
    @Published private(set) var snake: [CGPoint] = []
    @Published private(set) var food: CGPoint = .zero
    @Published private(set) var direction: CGVector = .init(dx: 1, dy: 0)
    @Published private(set) var nextDirection: CGVector = .init(dx: 1, dy: 0)
    @Published private(set) var score = 0
    @Published private(set) var highScore = 0
    @Published private(set) var isGameOver = false
    @Published private(set) var isPaused = false

    private var timer: AnyCancellable?

    init() {
        highScore = UserDefaults.standard.integer(forKey: "SnakeIOS.highScore")
        startNewGame()
    }

    func startNewGame() {
        stopTimer()
        let start = Self.cellCount / 2
        snake = [
            CGPoint(x: start, y: start),
            CGPoint(x: start - 1, y: start),
            CGPoint(x: start - 2, y: start),
        ]
        direction = .init(dx: 1, dy: 0)
        nextDirection = direction
        score = 0
        isGameOver = false
        isPaused = false
        placeFood()
        startTimer()
    }

    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
        isPaused ? stopTimer() : startTimer()
    }

    func setDirection(_ new: CGVector) {
        guard !isGameOver, !isPaused else { return }
        // Nunca permite meia-volta (180°) de uma só vez.
        guard new.dx != -direction.dx || new.dy != -direction.dy else { return }
        nextDirection = new
    }

    // MARK: - Timer

    private var interval: TimeInterval {
        let level = score / 50
        return max(Self.minInterval, Self.baseInterval - Double(level) * Self.speedStep)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: interval, tolerance: interval * 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.step() }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func step() {
        guard !isPaused, !isGameOver else { return }
        direction = nextDirection

        let head = snake[0]
        let newHead = CGPoint(x: head.x + direction.dx, y: head.y + direction.dy)

        // Colisão com a parede.
        guard newHead.x >= 0, newHead.x < Self.cellCount,
              newHead.y >= 0, newHead.y < Self.cellCount else {
            endGame()
            return
        }

        // Colisão com o próprio corpo (a cauda sai do último lugar, então ele pode ser reentrado).
        let body = Array(snake.dropLast())
        guard !body.contains(where: { $0 == newHead }) else {
            endGame()
            return
        }

        snake.insert(newHead, at: 0)

        if newHead == food {
            score += 10
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: "SnakeIOS.highScore")
            }
            placeFood()
        } else {
            snake.removeLast()
        }

        // Re-arranca o timer para aplicar o novo intervalo (velocidade maior).
        startTimer()
    }

    private func placeFood() {
        repeat {
            food = CGPoint(x: Int.random(in: 0..<Self.cellCount),
                           y: Int.random(in: 0..<Self.cellCount))
        } while snake.contains(where: { $0 == food })
    }

    private func endGame() {
        isGameOver = true
        stopTimer()
    }
}

// MARK: - Interface

struct SnakeGameView: View {
    @StateObject private var game = SnakeGame()

    var body: some View {
        GeometryReader { geometry in
            let boardSize = Self.boardSize(for: geometry)
            let cellSize = boardSize / CGFloat(SnakeGame.cellCount)

            ZStack {
                // Fundo verde escuro, quase preto.
                Color(red: 0.02, green: 0.08, blue: 0.04).ignoresSafeArea()

                VStack(spacing: 16) {
                    scoreRow
                    ZStack {
                        board(boardSize: boardSize, cellSize: cellSize)
                        gameOverCard
                    }
                    .frame(width: boardSize, height: boardSize)
                    .shadow(color: .black.opacity(0.7), radius: 24, x: 0, y: 0)
                    controls
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top : 8)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12))
                .gesture(dragGesture)
            }
        }
        .sensoryFeedback(.impact, trigger: game.score)
        .sensoryFeedback(.error, trigger: game.isGameOver)
    }

    // Tabuleiro quadrado que escala com a tela, dentro de limites seguros.
    private static func boardSize(for geometry: GeometryProxy) -> CGFloat {
        let minDim = min(geometry.size.width, geometry.size.height)
        return max(240, min(minDim - 48, 360))
    }

    // MARK: - Placar

    private var scoreRow: some View {
        HStack {
            Text("PONTOS").font(.caption2).fontWeight(.bold)
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text("\(game.score)")
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundColor(.green)
            Spacer()
            Text("RECORDE").font(.caption2).fontWeight(.bold)
                .foregroundColor(.white.opacity(0.55))
            Text("\(game.highScore)")
                .font(.subheadline).fontWeight(.semibold).monospacedDigit()
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Tabuleiro

    private func board(boardSize: CGFloat, cellSize: CGFloat) -> some View {
        Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<SnakeGame.cellCount, id: \.self) { row in
                GridRow {
                    ForEach(0..<SnakeGame.cellCount, id: \.self) { col in
                        cell(at: CGPoint(x: col, y: row))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(gridLines(cellSize: cellSize, count: SnakeGame.cellCount, size: boardSize), alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.05, green: 0.16, blue: 0.07))
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 4)
        .drawingGroup()
        .onTapGesture { game.togglePause() }
    }

    private func gridLines(cellSize: CGFloat, count: Int, size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let p = CGFloat(i) * cellSize
                Path { path in
                    path.move(to: .init(x: p, y: 0))
                    path.addLine(to: .init(x: p, y: size))
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                Path { path in
                    path.move(to: .init(x: 0, y: p))
                    path.addLine(to: .init(x: size, y: p))
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private func cell(at position: CGPoint) -> some View {
        let head = game.snake.first
        let isSnake = game.snake.contains(where: { $0 == position })

        return Group {
            if isSnake, let head, position == head {
                Rectangle().fill(Color.green).padding(1)
            } else if isSnake {
                Rectangle().fill(Color.green.opacity(0.85)).padding(1)
            } else if position == game.food {
                Circle().fill(Color.red).padding(4)
            } else {
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.12), value: game.snake)
        .animation(.easeInOut(duration: 0.12), value: game.food)
    }

    private var gameOverCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .shadow(color: .red.opacity(0.35), radius: 20, x: 0, y: 0)

            VStack(spacing: 14) {
                Text("GAME OVER")
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .foregroundColor(.red)
                Text("\(game.score) pontos")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                if game.score == game.highScore, game.score > 0 {
                    Text("Novo recorde!")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.green)
                }
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        game.startNewGame()
                    }
                } label: {
                    Text("▶ Jogar novamente")
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Capsule().fill(Color.green))
                .shadow(color: .green.opacity(0.45), radius: 10, x: 0, y: 0)
                .padding(.horizontal, 56)
            }
        }
        .opacity(game.isGameOver ? 1 : 0)
        .scaleEffect(game.isGameOver ? 1 : 0.9)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.isGameOver)
        .allowsHitTesting(game.isGameOver)
    }

    // MARK: - Controles

    private var controls: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "hand.draw")
                Text("Deslize para mudar de direção")
                    .font(.caption).fontWeight(.medium)
                Spacer()
            }
            .foregroundColor(.white.opacity(0.45))

            HStack(spacing: 14) {
                directionalButton("▲", .init(dx: 0, dy: -1))
                directionalButton("▼", .init(dx: 0, dy: 1))
                directionalButton("◀", .init(dx: -1, dy: 0))
                directionalButton("▶", .init(dx: 1, dy: 0))
            }
        }
        .padding(.horizontal, 30)
    }

    private func directionalButton(_ label: String, _ vector: CGVector) -> some View {
        Button {
            game.setDirection(vector)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .frame(width: 66, height: 66)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
        .disabled(game.isGameOver || game.isPaused)
        .opacity((game.isGameOver || game.isPaused) ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.15), value: game.isGameOver)
        .animation(.easeInOut(duration: 0.15), value: game.isPaused)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onEnded { value in
                let dx = value.location.x - value.startLocation.x
                let dy = value.location.y - value.startLocation.y
                let dir: CGVector
                if abs(dx) > abs(dy) {
                    dir = dx > 0 ? .init(dx: 1, dy: 0) : .init(dx: -1, dy: 0)
                } else {
                    dir = dy > 0 ? .init(dx: 0, dy: 1) : .init(dx: 0, dy: -1)
                }
                game.setDirection(dir)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
    }
}
