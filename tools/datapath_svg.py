"""Draws Media/datapath.svg, the datapath diagram in the README.
Usage: python tools/datapath_svg.py Media/datapath.svg
Coordinates are hand-placed; edit them here rather than the SVG."""
import sys

W, H = 1310, 850
out = []
def add(s): out.append(s)

def wire(*pts, ctl=False, arrow=True):
    d = " ".join(f"{x},{y}" for x, y in pts)
    cls = "ctl" if ctl else "w"
    add(f'<polyline class="{cls}" points="{d}"{" marker-end=\"url(#a)\"" if arrow and not ctl else ""}/>')

def dot(x, y): add(f'<circle cx="{x}" cy="{y}" r="3.2" class="dot"/>')
def text(x, y, s, cls="lbl", anchor="start"):
    add(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{s}</text>')
def box(x, y, w, h, title, sub=None):
    add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" class="blk"/>')
    cy = y + h / 2 + (0 if sub else 5)
    text(x + w / 2, cy - (4 if sub else 0), title, "ttl", "middle")
    if sub: text(x + w / 2, cy + 14, sub, "sub", "middle")
def mux(x, y, w, h, ins):
    add(f'<polygon class="mux" points="{x},{y} {x+w},{y+10} {x+w},{y+h-10} {x},{y+h}"/>')
    for yy, lab in ins: text(x + 3, yy + 4, lab, "mx")
def stub(x, y0, y1, label, anchor="middle", dx=0):
    wire((x, y1), (x, y0), ctl=True)
    ty = y1 - 4 if y1 < y0 else y1 + 12
    text(x + dx, ty, label, "cl", anchor)
def clock(x, y):  # small clock triangle on a bottom edge
    add(f'<polyline class="clk" points="{x-6},{y} {x},{y-8} {x+6},{y}"/>')
def adder(x, y):
    add(f'<rect x="{x}" y="{y}" width="36" height="44" rx="4" class="blk"/>')
    text(x + 18, y + 28, "+", "ttl", "middle")

# ---------------- control ----------------
box(560, 22, 520, 54, "Control",
    "reg_write · alu_src_a · alu_src_b · alu_op · mem_write · result_src · branch · jump · jalr · halt")
wire((375, 49), (560, 49))
text(382, 43, "opcode, funct3, inst[30]", "sm")

# ---------------- fetch ----------------
mux(70, 280, 28, 120, [(300, "00"), (340, "01"), (380, "10")])
stub(84, 392, 418, "pc_src")
box(125, 310, 50, 60, "PC")
clock(160, 370)
stub(140, 370, 392, "en = !halt")
wire((98, 340), (125, 340))
wire((175, 340), (225, 340))
dot(195, 340)
box(225, 285, 120, 110, "imem", "instructions")
wire((345, 340), (375, 340), arrow=False)
text(349, 333, "instr", "sm")

# PC + 4
adder(245, 168)
wire((195, 340), (195, 180), (245, 180))
wire((228, 200), (245, 200))
text(220, 205, "4", "lbl", "end")
wire((281, 190), (300, 190), (300, 130), arrow=False)
dot(300, 130)
wire((300, 130), (52, 130), (52, 300), (70, 300))            # pc+4 -> PC mux 00
wire((300, 130), (1185, 130), (1185, 220), (1220, 220))       # pc+4 -> result mux 10
text(700, 124, "pc_plus4", "sm", "middle")

# instruction bus
wire((375, 49), (375, 495), arrow=False)
for y, lab in [(300, "rs1 [19:15]"), (330, "rs2 [24:20]"), (360, "rd [11:7]"), (495, "inst")]:
    dot(375, y); wire((375, y), (440, y)); text(380, y - 4, lab, "sm")

# ---------------- decode ----------------
add('<rect x="440" y="270" width="120" height="160" rx="4" class="blk"/>')
text(500, 367, "regfile", "ttl", "middle"); text(500, 383, "32 × 32", "sub", "middle")
for y, lab in [(300, "A1"), (330, "A2"), (360, "A3"), (405, "WD")]: text(445, y + 4, lab, "port")
for y, lab in [(330, "RD1"), (390, "RD2")]: text(555, y + 4, lab, "port", "end")
clock(470, 430)
stub(520, 430, 452, "reg_write", "start", -14)
box(440, 470, 120, 50, "imm_gen", "I / S / B / U / J")

# pc -> src_a (route above the regfile)
dot(195, 250)
wire((195, 250), (630, 250), (630, 295), (640, 295))
text(250, 244, "pc", "sm")

# rd1 / rd2
wire((560, 330), (640, 330)); text(564, 324, "rd1", "sm")
dot(612, 330); wire((612, 330), (612, 185), (710, 185))
wire((560, 390), (640, 390)); text(564, 384, "rd2", "sm")
dot(622, 390); wire((622, 390), (622, 205), (710, 205))
dot(598, 390); wire((598, 390), (598, 560), (860, 560))
# imm_ext
wire((560, 495), (630, 495), arrow=False); text(636, 512, "imm_ext", "sm")
dot(630, 495); wire((630, 495), (630, 425), (640, 425))
wire((630, 495), (630, 674), (660, 674))

# ---------------- execute ----------------
mux(640, 275, 25, 75, [(295, "1"), (330, "0")])
stub(652, 279, 262, "alu_src_a", "start", 4)
mux(640, 365, 25, 80, [(390, "0"), (425, "1")])
stub(652, 441, 462, "alu_src_b", "start", 4)
wire((665, 312), (700, 312))
wire((665, 405), (700, 405))
add('<polygon class="blk" points="700,285 770,325 770,395 700,435 700,375 714,360 700,345"/>')
text(742, 365, "ALU", "ttl", "middle")
stub(735, 305, 268, "alu_op")

box(710, 165, 110, 60, "branch_unit")
stub(765, 165, 148, "funct3")
wire((820, 195), (870, 195)); text(826, 189, "taken", "sm")
box(870, 165, 110, 60, "next-PC", "select")
stub(925, 165, 148, "branch · jump · jalr")
wire((980, 195), (1005, 195), ctl=True); text(1009, 199, "pc_src", "cl")

# PC target adder
adder(660, 640)
dot(195, 650)
wire((195, 340), (195, 650), (660, 650))
wire((696, 662), (715, 662), (715, 740), (36, 740), (36, 340), (70, 340))
text(300, 734, "pc_target = pc + imm_ext", "sm")

# alu_result
wire((770, 360), (1030, 360)); text(830, 354, "alu_result", "sm")
dot(790, 360); wire((790, 360), (790, 780), (20, 780), (20, 380), (70, 380))
text(300, 774, "jalr target = {alu_result[31:1], 0}", "sm")
dot(820, 360); wire((820, 360), (820, 490), (860, 490)); text(826, 484, "[1:0]", "sm")
dot(1000, 360); wire((1000, 360), (1000, 265), (1220, 265))

# ---------------- memory ----------------
box(860, 470, 120, 110, "LSU", "byte lanes")
text(864, 494, "byte_off", "port"); text(864, 564, "rs2_data", "port")
stub(890, 470, 450, "funct3")
stub(950, 470, 450, "mem_write")
box(1030, 320, 120, 140, "dmem", "data")
for y, lab in [(360, "addr"), (395, "wdata"), (425, "be")]: text(1035, y + 4, lab, "port")
text(1145, 394, "rdata", "port", "end")
clock(1060, 460)
wire((980, 495), (1005, 495), (1005, 395), (1030, 395))
wire((980, 515), (1015, 515), (1015, 425), (1030, 425))
wire((1150, 390), (1165, 390), (1165, 540), (980, 540))
wire((980, 565), (1195, 565), (1195, 310), (1220, 310)); text(1050, 559, "load_data", "sm")

# ---------------- write back ----------------
mux(1220, 200, 30, 130, [(220, "10"), (265, "00"), (310, "01")])
stub(1235, 205, 186, "result_src")
wire((1250, 265), (1275, 265), (1275, 720), (410, 720), (410, 405), (440, 405))
text(1000, 714, "result", "sm")

# legend
lx, ly = 860, 812
wire((lx, ly), (lx + 40, ly), arrow=False); text(lx + 48, ly + 4, "data", "lgd")
wire((lx + 100, ly), (lx + 140, ly), ctl=True); text(lx + 148, ly + 4, "control (from Control)", "lgd")
dot(lx + 320, ly); text(lx + 330, ly + 4, "junction", "lgd")
text(20, 818, "RV32I single-cycle datapath", "cap")

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="Segoe UI, Helvetica, Arial, sans-serif">
<defs>
  <marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,1 L9,5 L0,9 z" fill="#24292f"/>
  </marker>
  <style>
    .w   {{ fill: none; stroke: #24292f; stroke-width: 1.6; }}
    .ctl {{ fill: none; stroke: #1f6feb; stroke-width: 1.3; stroke-dasharray: 5 3; }}
    .dot {{ fill: #24292f; }}
    .blk {{ fill: #f6f8fa; stroke: #24292f; stroke-width: 1.6; }}
    .mux {{ fill: #fff4d6; stroke: #24292f; stroke-width: 1.6; }}
    .clk {{ fill: none; stroke: #24292f; stroke-width: 1.2; }}
    .ttl {{ font-size: 15px; font-weight: 600; fill: #24292f; }}
    .sub {{ font-size: 11px; fill: #57606a; }}
    .lbl {{ font-size: 13px; fill: #24292f; }}
    .sm  {{ font-size: 11px; fill: #24292f; }}
    .port {{ font-size: 10px; fill: #57606a; }}
    .mx  {{ font-size: 9px; fill: #57606a; }}
    .cl  {{ font-size: 11px; fill: #1f6feb; }}
    .lgd {{ font-size: 12px; fill: #24292f; }}
    .cap {{ font-size: 13px; font-weight: 600; fill: #57606a; }}
  </style>
</defs>
<rect width="{W}" height="{H}" fill="#ffffff"/>
{chr(10).join(out)}
</svg>
'''
open(sys.argv[1], "w", encoding="utf-8").write(svg)
