import json
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
    return {phase: [q for q in data if q["fase"] == phase] for phase in range(1, 6)}

class EscapeRoom:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("PROTOCOLO DE FUGA | Escape Room")
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)
        self.clock = pygame.time.Clock()
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
        self.showing_error = False

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
        pygame.draw.rect(self.screen, COLORS["cyan"] if active else COLORS["line"], rect, 2, border_radius=9)
        self.draw_text(label, rect.centerx, rect.centery, COLORS["white"], self.small, True)
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

    def draw_background(self, w, h):
        self.screen.fill(COLORS["bg"])
        # Subtle futuristic grid.
        step = max(28, int(w / 35))
        for x in range(0, w, step):
            pygame.draw.line(self.screen, (11, 29, 48), (x, 0), (x, h), 1)
        for y in range(0, h, step):
            pygame.draw.line(self.screen, (11, 29, 48), (0, y), (w, y), 1)
        pygame.draw.rect(self.screen, COLORS["cyan"], (0, 0, w, 5))

    def render_desktop(self):
        w, h = self.screen.get_size()
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
        self.mobile_small = pygame.font.SysFont("consolas", max(15, min(20, int(w * .018))))
        self.mobile_font = pygame.font.SysFont("consolas", max(19, min(25, int(w * .022))))
        self.mobile_title = pygame.font.SysFont("consolas", max(23, min(31, int(w * .027))), bold=True)
        self.mobile_big = pygame.font.SysFont("consolas", max(34, min(48, int(w * .043))), bold=True)
        self.draw_background(w, h)

        if self.state == "start":
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
        self.mobile_small = pygame.font.SysFont("consolas", max(15, min(20, int(w * .018))))
        self.mobile_font = pygame.font.SysFont("consolas", max(19, min(25, int(w * .022))))
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
                elif event.type == pygame.VIDEORESIZE:
                    self.screen = pygame.display.set_mode(event.size, pygame.RESIZABLE)
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
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
