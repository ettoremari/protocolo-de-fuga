import json
import math
import os
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

def load_questions():
    with open(ROOT / "data" / "questoes.json", encoding="utf-8") as file:
        data = json.load(file)
    # Keep the game focused on its own original escape-room questions.
    data = [q for q in data if q.get("origem") != "enem" and not q.get("id", "").startswith("ENEM-")]
    return {phase: [q for q in data if q["fase"] == phase] for phase in range(1, 6)}


def android_density():
    """Return Android's physical-pixel scale, with a safe resolution fallback."""
    if "ANDROID_ARGUMENT" not in os.environ and sys.platform != "android":
        return 1.0
    try:
        from jnius import autoclass

        activity = autoclass("org.libsdl.app.SDLActivity").mSingleton
        return max(1.0, min(4.0, float(activity.getResources().getDisplayMetrics().density)))
    except Exception:
        # Pydroid builds can omit PyJNIus; estimate density from the portrait width.
        info = pygame.display.Info()
        width = info.current_w or pygame.display.get_surface().get_width()
        return max(1.0, min(3.5, width / 420.0))

class EscapeRoom:
    def __init__(self):
        pygame.init()
        self.music_enabled = True
        self.mobile_font_scale = 1.0
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
        self.android = "ANDROID_ARGUMENT" in os.environ or sys.platform == "android"
        self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN) if self.android else pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)
        self.ui_scale = android_density()
        self.mobile_scroll_y = 0
        self.mobile_scroll_max = 0
        self.mobile_touch_start = None
        self.mobile_touch_last_y = None
        self.clock = pygame.time.Clock()
        try:
            self.logo_image = pygame.image.load(str(ROOT / "assets" / "icon.png")).convert_alpha()
        except (pygame.error, FileNotFoundError):
            self.logo_image = None
        self.font = pygame.font.SysFont("consolas", 23)
        self.small = pygame.font.SysFont("consolas", 17)
        self.big = pygame.font.SysFont("consolas", 48, bold=True)
        self.title = pygame.font.SysFont("consolas", 34, bold=True)
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
        self.mobile_scroll_y = 0
        self.mobile_scroll_max = 0
        self.showing_error = False
        self.effect_started = None
        self.effect_color = COLORS['cyan']
        self.question_scroll = 0

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
        self.mobile_scroll_y = 0

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

    def button(self, rect, label, action=None, active=True, font=None):
        color = COLORS["panel2"] if active else (25, 35, 48)
        pygame.draw.rect(self.screen, color, rect, border_radius=9)
        pulse = (math.sin(pygame.time.get_ticks() / 260) + 1) / 2
        border = COLORS["cyan"] if active else COLORS["line"]
        if active:
            border = tuple(min(255, int(channel * (0.72 + pulse * 0.28))) for channel in border)
        pygame.draw.rect(self.screen, border, rect, 1 + int(pulse * 2) if active else 2, border_radius=9)
        is_mobile = self.screen.get_height() > self.screen.get_width() or self.android
        button_font = getattr(self, "mobile_small", self.small) if is_mobile else self.small
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

    @staticmethod
    def wrapped_lines(text, max_width, font):
        words = str(text).split()
        lines = []
        line = ""
        for word in words:
            test = (line + " " + word).strip()
            if font.size(test)[0] > max_width and line:
                lines.append(line)
                line = word
            else:
                line = test
        if line:
            lines.append(line)
        return lines

    def draw_background(self, w, h):
        self.screen.fill(COLORS["bg"])
        # Subtle futuristic grid.
        step = max(28, int(w / 35))
        for x in range(0, w, step):
            pygame.draw.line(self.screen, (11, 29, 48), (x, 0), (x, h), 1)
        for y in range(0, h, step):
            pygame.draw.line(self.screen, (11, 29, 48), (0, y), (w, y), 1)
        # A slow scan line gives the control room a little movement without assets.
        scan_y = (pygame.time.get_ticks() // 18) % max(1, h)
        pygame.draw.line(self.screen, (18, 57, 76), (0, scan_y), (w, scan_y), 2)
        pygame.draw.rect(self.screen, COLORS["cyan"], (0, 0, w, 5))

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

    def mobile_control_rects(self):
        w, h = self.screen.get_size()
        margin = max(16, int(w * 0.045))
        top = max(22, int(h * .035))
        button_h = 38
        music_w = min(132, max(100, int(w * .29)))
        music = pygame.Rect(w - margin - music_w, top, music_w, button_h)
        plus = pygame.Rect(music.left - 38, top, 34, button_h)
        minus = pygame.Rect(plus.left - 38, top, 34, button_h)
        return minus, plus, music

    def music_button_rect(self):
        w, h = self.screen.get_size()
        mobile = h > w or self.android
        scale = self.ui_scale if mobile else 1
        margin = max(int(16 * scale), int(w * 0.045)) if mobile else max(20, int(w * 0.055))
        width, height = (int(124 * scale), int(42 * scale)) if mobile else (154, 42)
        return pygame.Rect(w - margin - width, int(12 * scale), width, height)

    def draw_music_button(self):
        if self.screen.get_height() > self.screen.get_width() or self.android:
            scale = self.ui_scale
            logical_w = self.screen.get_width() / scale
            self.mobile_small = pygame.font.SysFont("consolas", int(max(14, min(19, logical_w * .045)) * scale))
        status = "INDISP." if not self.music_available else ("ON" if self.music_enabled else "OFF")
        self.button(self.music_button_rect(), f"SOM: {status}", active=self.music_available)

    def configure_mobile_fonts(self, width):
        scale = self.mobile_font_scale
        self.mobile_small = pygame.font.SysFont("consolas", max(16, min(39, round(max(19, min(28, int(width * .025))) * scale))))
        self.mobile_font = pygame.font.SysFont("consolas", max(19, min(50, round(max(24, min(36, int(width * .032))) * scale))))
        self.mobile_title = pygame.font.SysFont("consolas", max(16, min(42, round(max(20, min(30, int(width * .028))) * scale))), bold=True)
        self.mobile_big_size = max(27, min(67, round(max(34, min(48, int(width * .043))) * scale)))
        self.mobile_big = pygame.font.SysFont("consolas", self.mobile_big_size, bold=True)

    def draw_logo(self, rect):
        if self.logo_image:
            image = pygame.transform.smoothscale(self.logo_image, rect.size)
            self.screen.blit(image, rect)
        else:
            pygame.draw.rect(self.screen, COLORS["panel2"], rect, border_radius=max(5, rect.width // 5))
            pygame.draw.rect(self.screen, COLORS["cyan"], rect, 2, border_radius=max(5, rect.width // 5))
            pygame.draw.line(self.screen, COLORS["cyan"], (rect.x + rect.width // 3, rect.y + rect.height * 4 // 5), (rect.x + rect.width // 3, rect.y + rect.height // 4), 3)
            pygame.draw.line(self.screen, COLORS["cyan"], (rect.x + rect.width // 3, rect.y + rect.height // 4), (rect.x + rect.width * 2 // 3, rect.y + rect.height // 4), 3)
            pygame.draw.line(self.screen, COLORS["cyan"], (rect.x + rect.width * 2 // 3, rect.y + rect.height // 4), (rect.x + rect.width * 2 // 3, rect.y + rect.height * 2 // 3), 3)

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
        scale = min(1.0, h / 700)
        self.font = pygame.font.SysFont("consolas", max(15, min(23, int(min(w * .021, h * .033)))))
        self.small = pygame.font.SysFont("consolas", max(12, min(17, int(min(w * .016, h * .024)))))
        self.big = pygame.font.SysFont("consolas", max(30, min(48, int(min(w * .044, h * .07)))), bold=True)
        self.title = pygame.font.SysFont("consolas", max(21, min(34, int(min(w * .031, h * .05)))), bold=True)
        self.draw_background(w, h)
        margin = max(20, int(w * .055))
        if self.state == "start":
            self.draw_text("INSTALAÇÃO CIENTÍFICA // SETOR 07", margin, int(h*.17), COLORS["cyan"], self.small)
            self.draw_text("PROTOCOLO", margin, int(h*.28), COLORS["white"], self.big)
            self.draw_text("DE FUGA", margin, int(h*.39), COLORS["cyan"], self.big)
            self.wrap_text("O sistema central bloqueou as cinco áreas de saída. Resolva os desafios de Análise Combinatória e recupere o controle da instalação.", margin, int(h*.55), w-margin*2, COLORS["muted"], self.font)
            self.button(pygame.Rect(margin, int(h*.76), 250, 55), "INICIAR MISSÃO")
            self.draw_text("ENTER para iniciar  •  ESC para sair", margin, int(h*.88), COLORS["muted"], self.small)
        elif self.state in ("playing", "phase_complete"):
            self.draw_text("PROTOCOLO DE FUGA", margin, 22, COLORS["cyan"], self.small)
            self.draw_text(f"FASE {self.phase}/5  |  {PHASE_NAMES[self.phase-1]}", margin, int(58*scale), COLORS["white"], self.title)
            stats = f"ACERTOS {self.total_hits}/12     ERROS {self.errors}/{MAX_ERRORS}     TEMPO {self.remaining()//60:02}:{self.remaining()%60:02}"
            self.draw_text(stats, margin, int(112*scale), COLORS["muted"], self.small)
            bar = pygame.Rect(margin, int(145*scale), w-2*margin, max(5, int(9*scale)))
            pygame.draw.rect(self.screen, COLORS["panel2"], bar, border_radius=5)
            progress = int(bar.width * self.total_hits / 12)
            pygame.draw.rect(self.screen, COLORS["cyan"], (bar.x, bar.y, progress, bar.height), border_radius=5)
            panel = pygame.Rect(margin, int(h*.264), w-2*margin, int(h*.62))
            pygame.draw.rect(self.screen, COLORS["panel"], panel, border_radius=14)
            pygame.draw.rect(self.screen, COLORS["line"], panel, 2, border_radius=14)
            if self.state == "phase_complete":
                self.draw_text("SETOR DESBLOQUEADO", panel.centerx, panel.y+95, COLORS["green"], self.title, True)
                self.wrap_text("Acesso autorizado. O próximo setor está disponível.", panel.x+35, panel.y+155, panel.width-70, COLORS["white"], self.font)
                self.button(pygame.Rect(panel.x+35, panel.bottom-85, 260, 52), "AVANÇAR DE SETOR")
            elif self.current:
                content_view = pygame.Rect(panel.x + 20, panel.y + 60, panel.width - 40, panel.height - 150)
                self.draw_text(f"DESAFIO {self.current['id']}  •  {self.current['conteudo']}", panel.x+30, panel.y+28, COLORS["cyan"], self.small)
                hint = "ROLE PARA LER"
                self.draw_text(hint, panel.right-30-self.small.size(hint)[0], panel.y+28, COLORS["muted"], self.small)
                self.screen.set_clip(content_view)
                yy = self.wrap_text(self.current["enunciado"], panel.x+30, panel.y+75-self.question_scroll, panel.width-60, COLORS["white"], self.font, 10)
                if self.showing_error:
                    yy += 12
                    self.draw_text(self.feedback, panel.x+30, yy, COLORS["red"], self.small)
                    yy += 32
                    self.wrap_text(self.current["resolucao"], panel.x+30, yy, panel.width-60, COLORS["yellow"], self.small, 6)
                    self.screen.set_clip(None)
                    self.button(pygame.Rect(panel.x+30, panel.bottom-68, 245, 48), "PRÓXIMA QUESTÃO")
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
                    self.screen.set_clip(None)
                    submit_rect = pygame.Rect(panel.x+30, panel.bottom-68, 245, 48)
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
        scale = self.ui_scale
        margin = max(int(16 * scale), int(w * 0.045))
        panel = pygame.Rect(margin, int(150 * scale), w - 2 * margin, h - int(178 * scale))
        content_x = panel.x + int(22 * scale)
        content_width = panel.width - int(44 * scale)
        question_y = panel.y + int(88 * scale)
        return panel, content_x, content_width, question_y

    def render_mobile(self):
        w, h = self.screen.get_size()
        scale = self.ui_scale
        logical_w = w / scale
        margin = max(int(16 * scale), int(w * .045))
        self.mobile_small = pygame.font.SysFont("consolas", int(max(14, min(19, logical_w * .045)) * scale))
        self.mobile_font = pygame.font.SysFont("consolas", int(max(18, min(24, logical_w * .055)) * scale))
        self.mobile_title = pygame.font.SysFont("consolas", int(max(22, min(30, logical_w * .07)) * scale), bold=True)
        self.mobile_big = pygame.font.SysFont("consolas", int(max(34, min(48, logical_w * .11)) * scale), bold=True)
        self.draw_background(w, h)

        if self.state == "start":
            self.draw_text("INSTALAÇÃO CIENTÍFICA // SETOR 07", margin, safe_top + int(h * .16), COLORS["cyan"], self.mobile_small)
            logo_size = min(88, max(58, int(w * .18)))
            logo_rect = pygame.Rect(margin, safe_top + int(h * .275), logo_size, logo_size)
            self.draw_logo(logo_rect)
            title_x = logo_rect.right + 12
            title_size = min(self.mobile_big_size, max(24, int((w - margin - title_x) / 6.3)))
            start_title = pygame.font.SysFont("consolas", title_size, bold=True)
            self.draw_text("PROTOCOLO", title_x, safe_top + int(h * .275), COLORS["white"], start_title)
            self.draw_text("DE FUGA", title_x, safe_top + int(h * .36), COLORS["cyan"], start_title)
            self.wrap_text(
                "O sistema central bloqueou as cinco áreas de saída. Resolva os desafios de Análise Combinatória e recupere o controle da instalação.",
                margin, safe_top + int(h * .49), w - 2 * margin, COLORS["muted"], self.mobile_font, 10
            )
            self.button(pygame.Rect(margin, int(h * .76), w - 2 * margin, int(64 * scale)), "INICIAR MISSÃO")
            self.draw_text("Toque em INICIAR MISSÃO", margin, int(h * .86), COLORS["muted"], self.mobile_small)

        elif self.state in ("playing", "phase_complete"):
            self.draw_text("PROTOCOLO DE FUGA", margin, int(15 * scale), COLORS["cyan"], self.mobile_small)
            self.draw_text(f"FASE {self.phase}/5  |  {PHASE_NAMES[self.phase-1]}", margin, int(45 * scale), COLORS["white"], self.mobile_title)
            stats = f"ACERTOS {self.total_hits}/12   ERROS {self.errors}/{MAX_ERRORS}"
            self.draw_text(stats, margin, int(88 * scale), COLORS["muted"], self.mobile_small)
            time_text = f"TEMPO {self.remaining()//60:02}:{self.remaining()%60:02}"
            self.draw_text(time_text, w - margin, int(88 * scale), COLORS["yellow"], self.mobile_small, True)
            bar = pygame.Rect(margin, int(119 * scale), w - 2 * margin, int(8 * scale))
            pygame.draw.rect(self.screen, COLORS["panel2"], bar, border_radius=4)
            pygame.draw.rect(self.screen, COLORS["cyan"], (bar.x, bar.y, int(bar.width * self.total_hits / 12), bar.height), border_radius=4)
            panel, cx, cw, question_y = self.mobile_question_layout()
            pygame.draw.rect(self.screen, COLORS["panel"], panel, border_radius=14)
            pygame.draw.rect(self.screen, COLORS["line"], panel, 2, border_radius=14)

            if self.state == "phase_complete":
                self.draw_text("SETOR DESBLOQUEADO", panel.centerx, panel.y + int(115 * scale), COLORS["green"], self.mobile_title, True)
                self.wrap_text("Acesso autorizado. O próximo setor está disponível.", cx, panel.y + int(165 * scale), cw, COLORS["white"], self.mobile_font, int(10 * scale))
                self.button(pygame.Rect(cx, panel.bottom - int(88 * scale), cw, int(60 * scale)), "AVANÇAR DE SETOR")
            elif self.current:
                self.draw_text(f"DESAFIO {self.current['id']}", cx, panel.y + int(24 * scale), COLORS["cyan"], self.mobile_small)
                self.wrap_text(self.current["conteudo"], cx, panel.y + int(52 * scale), cw, COLORS["muted"], self.mobile_small, int(5 * scale))
                footer = 285 if self.current["tipo_resposta"] == "numeric" and not self.showing_error else 105
                body = pygame.Rect(panel.x + int(8 * scale), question_y, panel.width - int(16 * scale), max(1, panel.bottom - int(footer * scale) - question_y))
                raw_bottom = self.wrap_height(self.current["enunciado"], cw, self.mobile_font, int(9 * scale), question_y)
                if self.showing_error:
                    content_bottom = self.wrap_height(self.current["resolucao"], cw, self.mobile_font, int(8 * scale), raw_bottom + int(44 * scale))
                elif self.current["tipo_resposta"] == "choice":
                    content_bottom = raw_bottom + len(self.current["alternativas"]) * int(63 * scale)
                else:
                    content_bottom = raw_bottom
                self.mobile_scroll_max = max(0, content_bottom - body.bottom)
                self.mobile_scroll_y = min(self.mobile_scroll_y, self.mobile_scroll_max)
                previous_clip = self.screen.get_clip()
                self.screen.set_clip(body)
                yy = self.wrap_text(self.current["enunciado"], cx, question_y - self.mobile_scroll_y, cw, COLORS["white"], self.mobile_font, int(9 * scale))

                if self.showing_error:
                    yy += int(14 * scale)
                    self.draw_text(self.feedback, cx, yy, COLORS["red"], self.mobile_small)
                    yy += int(30 * scale)
                    self.wrap_text(self.current["resolucao"], cx, yy, cw, COLORS["yellow"], self.mobile_font, int(8 * scale))
                    self.screen.set_clip(previous_clip)
                    self.button(pygame.Rect(cx, panel.bottom - int(88 * scale), cw, int(60 * scale)), "PRÓXIMA QUESTÃO")
                elif self.current["tipo_resposta"] == "choice":
                    option_h = int(54 * scale)
                    option_gap = int(9 * scale)
                    self.mobile_option_rects = []
                    option_font = pygame.font.SysFont("consolas", max(20, min(25, self.mobile_font.get_height() - 4)))
                    option_y = yy
                    for idx, option in enumerate(self.current["alternativas"]):
                        lines = self.wrapped_lines(f"{chr(65+idx)})  {option}", cw - 28, option_font)
                        option_h = max(58, len(lines) * (option_font.get_linesize() + 2) + 10)
                        rect = pygame.Rect(cx, option_y, cw, option_h)
                        self.mobile_option_rects.append(rect)
                        pygame.draw.rect(self.screen, (24, 75, 91) if self.selected == idx else COLORS["panel2"], rect, border_radius=8)
                        pygame.draw.rect(self.screen, COLORS["cyan"] if self.selected == idx else COLORS["line"], rect, 2, border_radius=8)
                        # Vertically center the option label.
                        label = self.mobile_small.render(f"{chr(65+idx)})  {option}", True, COLORS["white"])
                        self.screen.blit(label, (rect.x + int(16 * scale), rect.centery - label.get_height() // 2))
                    self.screen.set_clip(previous_clip)
                    self.mobile_submit_rect = pygame.Rect(cx, panel.bottom - int(88 * scale), cw, int(60 * scale))
                    self.button(self.mobile_submit_rect, "VALIDAR RESPOSTA")
                else:
                    self.screen.set_clip(previous_clip)
                    input_rect = pygame.Rect(cx, yy + int(12 * scale), cw, int(54 * scale))
                    pygame.draw.rect(self.screen, COLORS["panel2"], input_rect, border_radius=8)
                    pygame.draw.rect(self.screen, COLORS["cyan"], input_rect, 2, border_radius=8)
                    shown = self.answer_text if self.answer_text else "RESPOSTA: toque nos números abaixo"
                    self.draw_text(shown, input_rect.x + int(14 * scale), input_rect.y + int(15 * scale), COLORS["white"] if self.answer_text else COLORS["muted"], self.mobile_small)

                    keys = ["1","2","3","4","5","6","7","8","9",",","0","⌫"]
                    key_gap = int(6 * scale)
                    key_h = int(40 * scale)
                    key_w = (cw - 2 * key_gap) // 3
                    keypad_bottom = panel.bottom - int(92 * scale)
                    keypad_top = keypad_bottom - (4 * key_h + 3 * key_gap)
                    self.mobile_key_rects = []
                    for idx, key in enumerate(keys):
                        row, col = divmod(idx, 3)
                        rect = pygame.Rect(cx + col * (key_w + key_gap), keypad_top + row * (key_h + key_gap), key_w, key_h)
                        self.mobile_key_rects.append((rect, key))
                        self.button(rect, key)
                    self.mobile_submit_rect = pygame.Rect(cx, panel.bottom - int(80 * scale), cw, int(54 * scale))
                    self.button(self.mobile_submit_rect, "VALIDAR RESPOSTA")

                if self.mobile_scroll_max:
                    track = pygame.Rect(panel.right - int(5 * scale), body.y, int(3 * scale), body.height)
                    thumb_h = max(int(24 * scale), int(track.height * body.height / (body.height + self.mobile_scroll_max)))
                    thumb_y = track.y + int((track.height - thumb_h) * self.mobile_scroll_y / self.mobile_scroll_max)
                    pygame.draw.rect(self.screen, COLORS["line"], track, border_radius=int(2 * scale))
                    pygame.draw.rect(self.screen, COLORS["cyan"], (track.x, thumb_y, track.width, thumb_h), border_radius=int(2 * scale))

            self.draw_text(f"ACERTOS NESTA FASE: {self.phase_hits}/{PHASE_TARGETS[self.phase-1]}", margin, h - int(20 * scale), COLORS["muted"], self.mobile_small)

        elif self.state in ("victory", "defeat"):
            won = self.state == "victory"
            self.draw_text("MISSÃO CONCLUÍDA" if won else "MISSÃO INTERROMPIDA", w // 2, int(h * .34), COLORS["green"] if won else COLORS["red"], self.mobile_title, True)
            self.draw_text("Você escapou da instalação!" if won else "O sistema de segurança bloqueou sua tentativa.", w // 2, int(h * .45), COLORS["white"], self.mobile_font, True)
            self.draw_text(f"Acertos: {self.total_hits}  |  Erros: {self.errors}", w // 2, int(h * .54), COLORS["muted"], self.mobile_small, True)
            self.button(pygame.Rect(margin, int(h * .67), w - 2 * margin, int(64 * scale)), "NOVA PARTIDA")
            self.draw_text("Toque no botão para reiniciar", w // 2, int(h * .79), COLORS["muted"], self.mobile_small, True)

        self.draw_music_button()
        self.draw_feedback_effect()
        pygame.display.flip()

    def render(self):
        w, h = self.screen.get_size()
        if h > w or self.android:
            self.render_mobile()
        else:
            self.render_desktop()

    def handle_mobile_click(self, pos):
        x, y = pos
        w, h = self.screen.get_size()
        scale = self.ui_scale
        margin = max(int(16 * scale), int(w * .045))
        panel, cx, cw, question_y = self.mobile_question_layout()

        if self.state == "start":
            safe_bottom = max(28, int(h * .06))
            if y >= h - safe_bottom - int(h * .12) - 58:
                self.start_game()
            return
        if self.state in ("victory", "defeat"):
            safe_bottom = max(28, int(h * .06))
            if y >= h - safe_bottom - int(h * .22) - 58:
                self.start_game()
            return
        if self.state == "phase_complete":
            if y >= panel.bottom - int(105 * scale):
                self.advance()
            return
        if self.state != "playing" or not self.current:
            return
        if self.showing_error:
            if y >= panel.bottom - int(105 * scale):
                self.advance()
            return

        # Recalculate the same wrapped question height used by render_mobile.
        logical_w = w / scale
        self.mobile_small = pygame.font.SysFont("consolas", int(max(14, min(19, logical_w * .045)) * scale))
        self.mobile_font = pygame.font.SysFont("consolas", int(max(18, min(24, logical_w * .055)) * scale))
        yy = self.wrap_height(self.current["enunciado"], cw, self.mobile_font, int(9 * scale), question_y) - self.mobile_scroll_y

        if self.current["tipo_resposta"] == "choice":
            option_h, option_gap = int(54 * scale), int(9 * scale)
            body = pygame.Rect(panel.x + int(8 * scale), question_y, panel.width - int(16 * scale), max(1, panel.bottom - int(105 * scale) - question_y))
            for idx in range(len(self.current["alternativas"])):
                rect = pygame.Rect(cx, yy + idx * (option_h + option_gap), cw, option_h)
                if body.collidepoint(pos) and rect.collidepoint(pos):
                    self.selected = idx
                    return
            if y >= panel.bottom - int(105 * scale):
                self.submit()
        else:
            keys = ["1","2","3","4","5","6","7","8","9",",","0","⌫"]
            key_gap, key_h = int(6 * scale), int(40 * scale)
            key_w = (cw - 2 * key_gap) // 3
            keypad_bottom = panel.bottom - int(92 * scale)
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
            if y >= panel.bottom - int(105 * scale):
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
            panel = pygame.Rect(margin, int(h*.264), w-2*margin, int(h*.62))
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.VIDEORESIZE:
                    if self.android:
                        self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
                        self.ui_scale = android_density()
                    else:
                        self.screen = pygame.display.set_mode(event.size, pygame.RESIZABLE)
                    self.mobile_scroll_y = 0
                elif event.type == pygame.MOUSEWHEEL and (h > w or self.android):
                    self.mobile_scroll_y = max(0, min(self.mobile_scroll_max, self.mobile_scroll_y - event.y * int(58 * self.ui_scale)))
                elif event.type == pygame.MOUSEMOTION and self.mobile_touch_start is not None:
                    delta_y = event.pos[1] - self.mobile_touch_last_y
                    if abs(event.pos[1] - self.mobile_touch_start[1]) > int(8 * self.ui_scale):
                        self.mobile_touch_dragged = True
                        self.mobile_scroll_y = max(0, min(self.mobile_scroll_max, self.mobile_scroll_y - delta_y))
                    self.mobile_touch_last_y = event.pos[1]
                elif event.type == pygame.MOUSEBUTTONUP and event.button == 1 and self.mobile_touch_start is not None:
                    if not getattr(self, "mobile_touch_dragged", False):
                        if self.music_button_rect().collidepoint(event.pos):
                            self.toggle_music()
                        else:
                            self.handle_mobile_click(event.pos)
                    self.mobile_touch_start = None
                    self.mobile_touch_last_y = None
                    self.mobile_touch_dragged = False
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
                    if h > w or self.android:
                        self.mobile_touch_start = event.pos
                        self.mobile_touch_last_y = event.pos[1]
                        self.mobile_touch_dragged = False
                        continue
                    if self.music_button_rect().collidepoint(event.pos):
                        self.toggle_music()
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
                            yy = panel.y + 75 - self.question_scroll
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
                            submit_rect = pygame.Rect(panel.x+30, panel.bottom-68, 245, 48)
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


