import json
import math
import random
import sys
import time
from pathlib import Path

import pygame

ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 1100, 700
FPS = 60
TOTAL_TIME = 20 * 60
MAX_ERRORS = 10
PHASE_TARGETS = [1, 2, 2, 3, 4]
PHASE_NAMES = [
    "CONTROLE DE ACESSO",
    "LABORATÓRIO BIOMÉTRICO",
    "CENTRAL DE SEGURANÇA",
    "COFRE DE DADOS",
    "NÚCLEO CENTRAL",
]

COLORS = {
    "bg": (7, 13, 28), "panel": (13, 27, 48), "panel2": (17, 39, 63),
    "cyan": (52, 220, 240), "blue": (60, 130, 255), "white": (232, 245, 255),
    "muted": (143, 174, 197), "green": (75, 220, 155), "red": (255, 91, 112),
    "yellow": (255, 207, 91), "line": (34, 91, 119)
}

# O SDL/Pygame no Android já trabalha com a resolução física da tela.
# Multiplicar novamente as fontes por 1.6 fazia textos e botões ficarem
# desproporcionais em aparelhos de alta densidade (como o Galaxy S24).
MOBILE_FONT_SCALE = 1.0


def mobile_sysfont(size, bold=False):
    return pygame.font.SysFont("consolas", max(12, round(size * MOBILE_FONT_SCALE)), bold=bold)



def load_questions():
    with open(ROOT / "data" / "questoes.json", encoding="utf-8") as file:
        data = json.load(file)
    return {phase: [q for q in data if q["fase"] == phase] for phase in range(1, 6)}

class EscapeRoom:
    def __init__(self):
        pygame.init()
        self.music_enabled = True
        self.music_available = False
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init()
            pygame.mixer.music.load(str(ROOT / "assets" / "tensefutureloop.ogg"))
            pygame.mixer.music.set_volume(0.28)
            pygame.mixer.music.play(-1)
            self.music_available = True
        except pygame.error:
            self.music_enabled = False
        pygame.display.set_caption("PROTOCOLO DE FUGA | Escape Room")
        is_android = hasattr(sys, "getandroidapilevel")
        self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN) if is_android else pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)
        self.clock = pygame.time.Clock()
        # Partículas persistentes: evita recriar objetos a cada quadro e mantém
        # a animação suave tanto em retrato quanto em paisagem.
        self.bg_particles = [
            {
                "x": random.uniform(0, WIDTH), "y": random.uniform(0, HEIGHT),
                "speed": random.uniform(9.0, 25.0),
                "drift": random.uniform(-7.0, 7.0),
                "radius": random.choice((1, 1, 2)),
                "phase": random.uniform(0, math.tau),
            }
            for _ in range(34)
        ]
        self.bg_last_tick = pygame.time.get_ticks()
        self.font = mobile_sysfont(23)
        self.small = mobile_sysfont(17)
        self.big = mobile_sysfont(48, bold=True)
        self.title = mobile_sysfont(34, bold=True)
        self.logo = None
        try:
            self.logo = pygame.image.load(str(ROOT / "assets" / "icon.png")).convert_alpha()
        except (pygame.error, OSError):
            pass
        self.questions = load_questions()
        self.state = "start"
        self.reset()

    def reset(self):
        self.phase = 1
        self.phase_hits = 0
        self.total_hits = 0
        self.errors = 0
        self.started_at = None
        self.used = {p: set() for p in range(1, 6)}
        self.current = None
        self.feedback = ""
        self.feedback_until = 0
        self.answer_text = ""
        self.selected = None
        self.showing_error = False
        self.effect_started = None
        self.effect_color = COLORS['cyan']

    def next_question(self):
        pool = self.questions[self.phase]
        available = [q for q in pool if q["id"] not in self.used[self.phase]]
        if not available:
            # The brief permits reuse only after all unseen questions have appeared.
            self.used[self.phase].clear()
            available = pool[:]
        self.current = random.choice(available)
        self.used[self.phase].add(self.current["id"])
        self.answer_text = ""
        self.selected = None
        self.showing_error = False
        self.feedback = ""

    def elapsed(self):
        return 0 if self.started_at is None else int(time.time() - self.started_at)

    def remaining(self):
        return max(0, TOTAL_TIME - self.elapsed())

    def start_game(self):
        self.reset()
        self.started_at = time.time()
        self.state = "playing"
        self.next_question()

    def submit(self):
        if not self.current or self.showing_error:
            return
        if self.current["tipo_resposta"] == "choice":
            if self.selected is None:
                self.feedback = "Selecione uma alternativa."
                self.feedback_until = time.time() + 2
                return
            value = self.current["alternativas"][self.selected]
        else:
            value = self.answer_text.strip()
            if not value:
                self.feedback = "Digite sua resposta."
                self.feedback_until = time.time() + 2
                return
        correct = str(value).strip().replace(",", ".") == str(self.current["resposta"]).strip()
        self.effect_started = pygame.time.get_ticks()
        self.effect_color = COLORS['green'] if correct else COLORS['red']
        if correct:
            self.total_hits += 1
            self.phase_hits += 1
            self.feedback = "ACESSO VALIDADO. RESPOSTA CORRETA."
            self.feedback_until = time.time() + 1.1
            if self.phase_hits >= PHASE_TARGETS[self.phase - 1]:
                if self.phase == 5:
                    self.state = "victory"
                else:
                    self.state = "phase_complete"
            else:
                self.next_after_feedback = True
        else:
            self.errors += 1
            self.showing_error = True
            self.feedback = "ACESSO NEGADO. ESTUDE A RESOLUÇÃO:"
            if self.errors >= MAX_ERRORS:
                self.state = "defeat"
            elif self.remaining() <= 0:
                self.state = "defeat"

    def advance(self):
        if self.state == "phase_complete":
            self.phase += 1
            self.phase_hits = 0
            self.state = "playing"
            self.next_question()
        elif self.state == "playing":
            self.next_question()

    def draw_text(self, text, x, y, color=None, font=None, center=False):
        surf = (font or self.font).render(str(text), True, color or COLORS["white"])
        rect = surf.get_rect()
        if center:
            rect.center = (x, y)
        else:
            rect.topleft = (x, y)
        self.screen.blit(surf, rect)
        return rect

    def button(self, rect, label, action=None, active=True):
        color = COLORS["panel2"] if active else (25, 35, 48)
        pygame.draw.rect(self.screen, color, rect, border_radius=9)
        pulse = (math.sin(pygame.time.get_ticks() / 260) + 1) / 2
        border = COLORS["cyan"] if active else COLORS["line"]
        if active:
            border = tuple(min(255, int(channel * (0.72 + pulse * 0.28))) for channel in border)
        pygame.draw.rect(self.screen, border, rect, 1 + int(pulse * 2) if active else 2, border_radius=9)
        button_font = getattr(self, "mobile_small", self.small) if self.screen.get_height() > self.screen.get_width() else self.small
        self.draw_text(label, rect.centerx, rect.centery, COLORS["white"], button_font, True)
        return rect

    def wrap_text(self, text, x, y, max_width, color=None, font=None, line_gap=8):
        font = font or self.font
        words = text.split()
        line = ""
        yy = y
        for word in words:
            test = (line + " " + word).strip()
            if font.size(test)[0] > max_width and line:
                self.draw_text(line, x, yy, color, font)
                yy += font.get_linesize() + line_gap
                line = word
            else:
                line = test
        if line:
            self.draw_text(line, x, yy, color, font)
            yy += font.get_linesize() + line_gap
        return yy

    def draw_logo(self, w, h):
        if self.logo is None:
            return
        max_size = max(64, min(112, int(w * 0.22)))
        logo = pygame.transform.smoothscale(self.logo, (max_size, max_size))
        self.screen.blit(logo, ((w - max_size) // 2, max(12, int(h * 0.045))))

    def draw_background(self, w, h):
        self.screen.fill(COLORS["bg"])
        now = pygame.time.get_ticks()
        dt = min(0.05, max(0.0, (now - self.bg_last_tick) / 1000.0))
        self.bg_last_tick = now

        # Grade técnica com brilho discreto e pulsação lenta.
        step = max(28, int(w / 35))
        pulse = (math.sin(now / 1250.0) + 1.0) / 2.0
        grid_color = (11 + int(pulse * 3), 27 + int(pulse * 5), 45 + int(pulse * 8))
        for x in range(0, w, step):
            pygame.draw.line(self.screen, grid_color, (x, 0), (x, h), 1)
        for y in range(0, h, step):
            pygame.draw.line(self.screen, grid_color, (0, y), (w, y), 1)

        # Partículas com velocidades, direções e fases diferentes.
        points = []
        for particle in self.bg_particles:
            particle["y"] -= particle["speed"] * dt
            particle["x"] += particle["drift"] * dt
            if particle["y"] < -8:
                particle["y"] = h + random.uniform(0, 24)
                particle["x"] = random.uniform(0, w)
            if particle["x"] < -8:
                particle["x"] = w + 8
            elif particle["x"] > w + 8:
                particle["x"] = -8
            x, y = int(particle["x"]), int(particle["y"])
            points.append((x, y))
            shimmer = (math.sin(now / 420.0 + particle["phase"]) + 1.0) / 2.0
            brightness = int(75 + shimmer * 100)
            pygame.draw.circle(
                self.screen, (15, brightness, min(255, brightness + 35)),
                (x, y), particle["radius"]
            )

        # Conexões curtas entre pontos próximos dão profundidade sem pesar.
        max_distance_sq = max(72, min(125, w // 8)) ** 2
        for i, (x1, y1) in enumerate(points):
            for x2, y2 in points[i + 1:]:
                dx, dy = x2 - x1, y2 - y1
                distance_sq = dx * dx + dy * dy
                if distance_sq < max_distance_sq:
                    alpha = max(0, 30 - int(30 * distance_sq / max_distance_sq))
                    if alpha:
                        pygame.draw.line(self.screen, (12, 65 + alpha, 88 + alpha), (x1, y1), (x2, y2), 1)

        # Varredura diagonal/luminosa em movimento contínuo.
        scan_y = (now // 18) % max(1, h)
        pygame.draw.line(self.screen, (18, 57, 76), (0, scan_y), (w, scan_y), 2)
        glow_y = (now // 31) % max(1, h + 90) - 45
        pygame.draw.line(self.screen, (10, 37, 55), (0, glow_y), (w, glow_y + 34), 3)
        pygame.draw.rect(self.screen, COLORS["cyan"], (0, 0, w, 4))

    def draw_feedback_effect(self):
        if self.effect_started is None:
            return
        elapsed = pygame.time.get_ticks() - self.effect_started
        duration = 360
        if elapsed >= duration:
            self.effect_started = None
            return
        overlay = pygame.Surface(self.screen.get_size(), pygame.SRCALPHA)
        overlay.fill((*self.effect_color, int(54 * (1 - elapsed / duration))))
        self.screen.blit(overlay, (0, 0))

    def music_button_rect(self):
        w, h = self.screen.get_size()
        margin = max(16, int(w * 0.045)) if h > w else max(20, int(w * 0.055))
        width, height = (124, 42) if h > w else (154, 42)
        return pygame.Rect(w - margin - width, 12, width, height)

    def draw_music_button(self):
        if self.screen.get_height() > self.screen.get_width():
            self.mobile_small = mobile_sysfont(max(15, min(20, int(self.screen.get_width() * .018))))
        status = "INDISP." if not self.music_available else ("ON" if self.music_enabled else "OFF")
        self.button(self.music_button_rect(), f"SOM: {status}", active=self.music_available)

    def toggle_music(self):
        if not self.music_available:
            return
        if self.music_enabled:
            pygame.mixer.music.pause()
            self.music_enabled = False
        else:
            pygame.mixer.music.unpause()
            self.music_enabled = True

    def render_desktop(self):
        w, h = self.screen.get_size()
        self.draw_background(w, h)
        margin = max(20, int(w * .055))
        if self.state == "start":
            self.draw_logo(w, h)
            self.draw_text("INSTALAÇÃO CIENTÍFICA // SETOR 07", margin, int(h*.17), COLORS["cyan"], self.small)
            self.draw_text("PROTOCOLO", margin, int(h*.28), COLORS["white"], self.big)
            self.draw_text("DE FUGA", margin, int(h*.39), COLORS["cyan"], self.big)
            self.wrap_text("O sistema central bloqueou as cinco áreas de saída. Resolva os desafios de Análise Combinatória e recupere o controle da instalação.", margin, int(h*.55), w-margin*2, COLORS["muted"], self.font)
            self.button(pygame.Rect(margin, int(h*.76), 250, 55), "INICIAR MISSÃO")
            self.draw_text("ENTER para iniciar  •  ESC para sair", margin, int(h*.88), COLORS["muted"], self.small)
        elif self.state in ("playing", "phase_complete"):
            self.draw_text("PROTOCOLO DE FUGA", margin, 22, COLORS["cyan"], self.small)
            self.draw_text(f"FASE {self.phase}/5  |  {PHASE_NAMES[self.phase-1]}", margin, 58, COLORS["white"], self.title)
            stats = f"ACERTOS {self.total_hits}/12     ERROS {self.errors}/{MAX_ERRORS}     TEMPO {self.remaining()//60:02}:{self.remaining()%60:02}"
            self.draw_text(stats, margin, 112, COLORS["muted"], self.small)
            bar = pygame.Rect(margin, 145, w-2*margin, 9)
            pygame.draw.rect(self.screen, COLORS["panel2"], bar, border_radius=5)
            progress = int(bar.width * self.total_hits / 12)
            pygame.draw.rect(self.screen, COLORS["cyan"], (bar.x, bar.y, progress, bar.height), border_radius=5)
            panel = pygame.Rect(margin, 185, w-2*margin, int(h*.62))
            pygame.draw.rect(self.screen, COLORS["panel"], panel, border_radius=14)
            pygame.draw.rect(self.screen, COLORS["line"], panel, 2, border_radius=14)
            if self.state == "phase_complete":
                self.draw_text("SETOR DESBLOQUEADO", panel.centerx, panel.y+95, COLORS["green"], self.title, True)
                self.wrap_text("Acesso autorizado. O próximo setor está disponível.", panel.x+35, panel.y+155, panel.width-70, COLORS["white"], self.font)
                self.button(pygame.Rect(panel.x+35, panel.bottom-85, 260, 52), "AVANÇAR DE SETOR")
            elif self.current:
                self.draw_text(f"DESAFIO {self.current['id']}  •  {self.current['conteudo']}", panel.x+30, panel.y+28, COLORS["cyan"], self.small)
                yy = self.wrap_text(self.current["enunciado"], panel.x+30, panel.y+75, panel.width-60, COLORS["white"], self.font, 10)
                if self.showing_error:
                    yy += 12
                    self.draw_text(self.feedback, panel.x+30, yy, COLORS["red"], self.small)
                    yy += 32
                    yy = self.wrap_text(self.current["resolucao"], panel.x+30, yy, panel.width-60, COLORS["yellow"], self.small, 6)
                    self.button(pygame.Rect(panel.x+30, panel.bottom-78, 245, 48), "PRÓXIMA QUESTÃO")
                else:
                    if self.current["tipo_resposta"] == "choice":
                        for idx, option in enumerate(self.current["alternativas"]):
                            r = pygame.Rect(panel.x+30, yy+idx*43, min(430,panel.width-60), 35)
                            pygame.draw.rect(self.screen, COLORS["panel2"] if self.selected != idx else (24, 75, 91), r, border_radius=6)
                            pygame.draw.rect(self.screen, COLORS["cyan"] if self.selected == idx else COLORS["line"], r, 1, border_radius=6)
                            self.draw_text(f"{chr(65+idx)})  {option}", r.x+12, r.y+7, COLORS["white"], self.small)
                    else:
                        input_rect = pygame.Rect(panel.x+30, yy+12, min(430,panel.width-60), 48)
                        pygame.draw.rect(self.screen, COLORS["panel2"], input_rect, border_radius=7)
                        pygame.draw.rect(self.screen, COLORS["cyan"], input_rect, 2, border_radius=7)
                        self.draw_text(self.answer_text or "Digite um número...", input_rect.x+14, input_rect.y+13, COLORS["white"] if self.answer_text else COLORS["muted"], self.small)
                    submit_rect = pygame.Rect(panel.x+30, panel.bottom-78, 245, 48)
                    self.button(submit_rect, "VALIDAR RESPOSTA")
                    if self.feedback and time.time() < self.feedback_until:
                        self.draw_text(self.feedback, panel.x+300, panel.bottom-63, COLORS["yellow"], self.small)
            self.draw_text(f"ACERTOS NESTA FASE: {self.phase_hits}/{PHASE_TARGETS[self.phase-1]}", margin, h-35, COLORS["muted"], self.small)
        elif self.state in ("victory", "defeat"):
            won = self.state == "victory"
            self.draw_text("MISSÃO CONCLUÍDA" if won else "MISSÃO INTERROMPIDA", w//2, int(h*.32), COLORS["green"] if won else COLORS["red"], self.big, True)
            self.draw_text("Você escapou da instalação!" if won else "O sistema de segurança bloqueou sua tentativa.", w//2, int(h*.45), COLORS["white"], self.font, True)
            self.draw_text(f"Acertos: {self.total_hits}  |  Erros: {self.errors}  |  Tempo restante: {self.remaining()//60:02}:{self.remaining()%60:02}", w//2, int(h*.55), COLORS["muted"], self.small, True)
            self.button(pygame.Rect(w//2-125, int(h*.68), 250, 55), "NOVA PARTIDA")
            self.draw_text("ENTER para reiniciar  •  ESC para sair", w//2, int(h*.82), COLORS["muted"], self.small, True)
        self.draw_music_button()
        self.draw_feedback_effect()
        pygame.display.flip()


    def mobile_question_layout(self):
        w, h = self.screen.get_size()
        margin = max(16, int(w * 0.045))
        panel = pygame.Rect(margin, 150, w - 2 * margin, h - 178)
        content_x = panel.x + 22
        content_width = panel.width - 44
        question_y = panel.y + 88
        return panel, content_x, content_width, question_y

    def render_mobile(self):
        w, h = self.screen.get_size()
        margin = max(16, int(w * 0.045))
        self.mobile_small = mobile_sysfont(max(15, min(20, int(w * .018))))
        self.mobile_font = mobile_sysfont(max(19, min(25, int(w * .022))))
        self.mobile_title = mobile_sysfont(max(23, min(31, int(w * .027))), bold=True)
        self.mobile_big = mobile_sysfont(max(34, min(48, int(w * .043))), bold=True)
        self.draw_background(w, h)

        if self.state == "start":
            self.draw_logo(w, h)
            self.draw_text("INSTALAÇÃO CIENTÍFICA // SETOR 07", margin, int(h * .20), COLORS["cyan"], self.mobile_small)
            self.draw_text("PROTOCOLO", margin, int(h * .32), COLORS["white"], self.mobile_big)
            self.draw_text("DE FUGA", margin, int(h * .41), COLORS["cyan"], self.mobile_big)
            self.wrap_text(
                "O sistema central bloqueou as cinco áreas de saída. Resolva os desafios de Análise Combinatória e recupere o controle da instalação.",
                margin, int(h * .54), w - 2 * margin, COLORS["muted"], self.mobile_font, 10
            )
            self.button(pygame.Rect(margin, int(h * .76), w - 2 * margin, 64), "INICIAR MISSÃO")
            self.draw_text("Toque em INICIAR MISSÃO", margin, int(h * .86), COLORS["muted"], self.mobile_small)

        elif self.state in ("playing", "phase_complete"):
            self.draw_text("PROTOCOLO DE FUGA", margin, 15, COLORS["cyan"], self.mobile_small)
            self.draw_text(f"FASE {self.phase}/5  |  {PHASE_NAMES[self.phase-1]}", margin, 45, COLORS["white"], self.mobile_title)
            stats = f"ACERTOS {self.total_hits}/12   ERROS {self.errors}/{MAX_ERRORS}"
            self.draw_text(stats, margin, 88, COLORS["muted"], self.mobile_small)
            time_text = f"TEMPO {self.remaining()//60:02}:{self.remaining()%60:02}"
            self.draw_text(time_text, w - margin, 88, COLORS["yellow"], self.mobile_small, True)
            bar = pygame.Rect(margin, 119, w - 2 * margin, 8)
            pygame.draw.rect(self.screen, COLORS["panel2"], bar, border_radius=4)
            pygame.draw.rect(self.screen, COLORS["cyan"], (bar.x, bar.y, int(bar.width * self.total_hits / 12), bar.height), border_radius=4)
            panel, cx, cw, question_y = self.mobile_question_layout()
            pygame.draw.rect(self.screen, COLORS["panel"], panel, border_radius=14)
            pygame.draw.rect(self.screen, COLORS["line"], panel, 2, border_radius=14)

            if self.state == "phase_complete":
                self.draw_text("SETOR DESBLOQUEADO", panel.centerx, panel.y + 115, COLORS["green"], self.mobile_title, True)
                self.wrap_text("Acesso autorizado. O próximo setor está disponível.", cx, panel.y + 165, cw, COLORS["white"], self.mobile_font, 10)
                self.button(pygame.Rect(cx, panel.bottom - 88, cw, 60), "AVANÇAR DE SETOR")
            elif self.current:
                self.draw_text(f"DESAFIO {self.current['id']}", cx, panel.y + 24, COLORS["cyan"], self.mobile_small)
                self.wrap_text(self.current["conteudo"], cx, panel.y + 52, cw, COLORS["muted"], self.mobile_small, 5)
                yy = self.wrap_text(self.current["enunciado"], cx, question_y, cw, COLORS["white"], self.mobile_font, 9)

                if self.showing_error:
                    yy += 14
                    self.draw_text(self.feedback, cx, yy, COLORS["red"], self.mobile_small)
                    yy += 30
                    self.wrap_text(self.current["resolucao"], cx, yy, cw, COLORS["yellow"], self.mobile_font, 8)
                    self.button(pygame.Rect(cx, panel.bottom - 88, cw, 60), "PRÓXIMA QUESTÃO")
                elif self.current["tipo_resposta"] == "choice":
                    option_h = 54
                    option_gap = 9
                    self.mobile_option_rects = []
                    for idx, option in enumerate(self.current["alternativas"]):
                        rect = pygame.Rect(cx, yy + idx * (option_h + option_gap), cw, option_h)
                        self.mobile_option_rects.append(rect)
                        pygame.draw.rect(self.screen, (24, 75, 91) if self.selected == idx else COLORS["panel2"], rect, border_radius=8)
                        pygame.draw.rect(self.screen, COLORS["cyan"] if self.selected == idx else COLORS["line"], rect, 2, border_radius=8)
                        # Vertically center the option label.
                        label = self.mobile_font.render(f"{chr(65+idx)})  {option}", True, COLORS["white"])
                        self.screen.blit(label, (rect.x + 16, rect.centery - label.get_height() // 2))
                    self.mobile_submit_rect = pygame.Rect(cx, panel.bottom - 88, cw, 60)
                    self.button(self.mobile_submit_rect, "VALIDAR RESPOSTA")
                else:
                    input_rect = pygame.Rect(cx, yy + 12, cw, 54)
                    pygame.draw.rect(self.screen, COLORS["panel2"], input_rect, border_radius=8)
                    pygame.draw.rect(self.screen, COLORS["cyan"], input_rect, 2, border_radius=8)
                    shown = self.answer_text if self.answer_text else "RESPOSTA: toque nos números abaixo"
                    self.draw_text(shown, input_rect.x + 14, input_rect.y + 15, COLORS["white"] if self.answer_text else COLORS["muted"], self.mobile_small)

                    keys = ["1","2","3","4","5","6","7","8","9",",","0","⌫"]
                    key_gap = 8
                    key_h = 45
                    key_w = (cw - 2 * key_gap) // 3
                    keypad_bottom = panel.bottom - 104
                    keypad_top = keypad_bottom - (4 * key_h + 3 * key_gap)
                    self.mobile_key_rects = []
                    for idx, key in enumerate(keys):
                        row, col = divmod(idx, 3)
                        rect = pygame.Rect(cx + col * (key_w + key_gap), keypad_top + row * (key_h + key_gap), key_w, key_h)
                        self.mobile_key_rects.append((rect, key))
                        self.button(rect, key)
                    self.mobile_submit_rect = pygame.Rect(cx, panel.bottom - 88, cw, 60)
                    self.button(self.mobile_submit_rect, "VALIDAR RESPOSTA")

            self.draw_text(f"ACERTOS NESTA FASE: {self.phase_hits}/{PHASE_TARGETS[self.phase-1]}", margin, h - 20, COLORS["muted"], self.mobile_small)

        elif self.state in ("victory", "defeat"):
            won = self.state == "victory"
            self.draw_text("MISSÃO CONCLUÍDA" if won else "MISSÃO INTERROMPIDA", w // 2, int(h * .34), COLORS["green"] if won else COLORS["red"], self.mobile_title, True)
            self.draw_text("Você escapou da instalação!" if won else "O sistema de segurança bloqueou sua tentativa.", w // 2, int(h * .45), COLORS["white"], self.mobile_font, True)
            self.draw_text(f"Acertos: {self.total_hits}  |  Erros: {self.errors}", w // 2, int(h * .54), COLORS["muted"], self.mobile_small, True)
            self.button(pygame.Rect(margin, int(h * .67), w - 2 * margin, 64), "NOVA PARTIDA")
            self.draw_text("Toque no botão para reiniciar", w // 2, int(h * .79), COLORS["muted"], self.mobile_small, True)

        self.draw_music_button()
        self.draw_feedback_effect()
        pygame.display.flip()

    def render(self):
        w, h = self.screen.get_size()
        if h > w:
            self.render_mobile()
        else:
            self.render_desktop()

    def handle_mobile_click(self, pos):
        x, y = pos
        w, h = self.screen.get_size()
        margin = max(16, int(w * .045))
        panel, cx, cw, question_y = self.mobile_question_layout()

        if self.state == "start":
            if y >= h * .68:
                self.start_game()
            return
        if self.state in ("victory", "defeat"):
            if y >= h * .62:
                self.start_game()
            return
        if self.state == "phase_complete":
            if y >= panel.bottom - 105:
                self.advance()
            return
        if self.state != "playing" or not self.current:
            return
        if self.showing_error:
            if y >= panel.bottom - 105:
                self.advance()
            return

        # Recalculate the same wrapped question height used by render_mobile.
        self.mobile_small = mobile_sysfont(max(15, min(20, int(w * .018))))
        self.mobile_font = mobile_sysfont(max(19, min(25, int(w * .022))))
        yy = self.wrap_height(self.current["enunciado"], cw, self.mobile_font, 9, question_y)

        if self.current["tipo_resposta"] == "choice":
            option_h, option_gap = 54, 9
            for idx in range(len(self.current["alternativas"])):
                rect = pygame.Rect(cx, yy + idx * (option_h + option_gap), cw, option_h)
                if rect.collidepoint(pos):
                    self.selected = idx
                    return
            if y >= panel.bottom - 105:
                self.submit()
        else:
            keys = ["1","2","3","4","5","6","7","8","9",",","0","⌫"]
            key_gap, key_h = 8, 45
            key_w = (cw - 2 * key_gap) // 3
            keypad_bottom = panel.bottom - 104
            keypad_top = keypad_bottom - (4 * key_h + 3 * key_gap)
            for idx, key in enumerate(keys):
                row, col = divmod(idx, 3)
                rect = pygame.Rect(cx + col * (key_w + key_gap), keypad_top + row * (key_h + key_gap), key_w, key_h)
                if rect.collidepoint(pos):
                    if key == "⌫":
                        self.answer_text = self.answer_text[:-1]
                    elif key == ",":
                        if "," not in self.answer_text and "." not in self.answer_text:
                            self.answer_text += ","
                    else:
                        self.answer_text += key
                    return
            if y >= panel.bottom - 105:
                self.submit()

    @staticmethod
    def wrap_height(text, max_width, font, line_gap, start_y):
        words = text.split()
        line = ""
        lines = 0
        for word in words:
            test = (line + " " + word).strip()
            if font.size(test)[0] > max_width and line:
                lines += 1
                line = word
            else:
                line = test
        if line:
            lines += 1
        return start_y + lines * (font.get_linesize() + line_gap)

    def run(self):
        running = True
        while running:
            self.clock.tick(FPS)
            w, h = self.screen.get_size()
            margin = max(20, int(w * .055))
            panel = pygame.Rect(margin, 185, w-2*margin, int(h*.62))
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type in (
                    pygame.VIDEORESIZE,
                    getattr(pygame, "WINDOWSIZECHANGED", -1000),
                    getattr(pygame, "WINDOWRESIZED", -1001),
                ):
                    # No Android a rotação pode chegar como evento de janela, não
                    # apenas VIDEORESIZE. Nunca chamar set_mode durante a rotação:
                    # isso pode invalidar a superfície SDL e encerrar o aplicativo.
                    surface = pygame.display.get_surface()
                    if surface is not None:
                        self.screen = surface
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key == pygame.K_m:
                        self.toggle_music()
                    elif self.state == "start" and event.key == pygame.K_RETURN:
                        self.start_game()
                    elif self.state in ("victory", "defeat") and event.key == pygame.K_RETURN:
                        self.start_game()
                    elif self.state == "playing" and self.current and not self.showing_error:
                        if self.current["tipo_resposta"] == "numeric":
                            if event.key == pygame.K_BACKSPACE:
                                self.answer_text = self.answer_text[:-1]
                            elif event.unicode.isdigit() or event.unicode in ",.":
                                self.answer_text += event.unicode
                            elif event.key == pygame.K_RETURN:
                                self.submit()
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if self.music_button_rect().collidepoint(event.pos):
                        self.toggle_music()
                        continue
                    if h > w:
                        self.handle_mobile_click(event.pos)
                        continue
                    x,y = event.pos
                    if self.state == "start":
                        if y > h*.70:
                            self.start_game()
                    elif self.state in ("victory", "defeat"):
                        if y > h*.62:
                            self.start_game()
                    elif self.state == "phase_complete":
                        if y > panel.bottom-105:
                            self.advance()
                    elif self.state == "playing" and self.current:
                        if self.showing_error:
                            if y > panel.bottom-100:
                                self.advance()
                        else:
                            yy = panel.y + 75
                            # Match the question wrapping calculation for choices.
                            words = self.current["enunciado"].split()
                            line, lines = "", 0
                            for word in words:
                                test = (line+" "+word).strip()
                                if self.font.size(test)[0] > panel.width-60 and line:
                                    lines += 1
                                    line = word
                                else:
                                    line = test
                            yy += (lines+1)*(self.font.get_linesize()+10)
                            if self.current["tipo_resposta"] == "choice":
                                for idx in range(len(self.current["alternativas"])):
                                    r = pygame.Rect(panel.x+30, yy+idx*43, min(430,panel.width-60), 35)
                                    if r.collidepoint(x,y):
                                        self.selected = idx
                            submit_rect = pygame.Rect(panel.x+30, panel.bottom-78, 245, 48)
                            if submit_rect.collidepoint(x,y):
                                self.submit()
            if self.state == "playing" and self.remaining() <= 0:
                self.state = "defeat"
            if self.state == "playing" and getattr(self, "next_after_feedback", False) and time.time() >= self.feedback_until:
                self.next_after_feedback = False
                self.next_question()
            self.render()
        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    EscapeRoom().run()

