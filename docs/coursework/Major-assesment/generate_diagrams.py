"""
Generate all 6 UML/architecture diagrams for the Pre-Capstone Research Proposal.
Uses matplotlib for rendering — no external dependencies needed.
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Arc
import numpy as np
import os

OUTPUT_DIR = r"C:\Users\LENOVO\Desktop\Capstone-Project\Major-assesment\diagrams"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ─── Color Palette ──────────────────────────────────────────────────────────
C_PRIMARY = '#2C3E50'      # dark blue-gray
C_SECONDARY = '#3498DB'    # blue
C_ACCENT = '#E74C3C'       # red
C_SUCCESS = '#27AE60'      # green
C_WARNING = '#F39C12'      # orange
C_LIGHT = '#ECF0F1'        # light gray
C_WHITE = '#FFFFFF'
C_TEXT = '#2C3E50'
C_PURPLE = '#8E44AD'
C_TEAL = '#1ABC9C'

def save_fig(fig, name):
    path = os.path.join(OUTPUT_DIR, name)
    fig.savefig(path, dpi=200, bbox_inches='tight', facecolor='white', edgecolor='none')
    plt.close(fig)
    print(f"  Saved: {path}")


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 1: Agile Development Model
# ═════════════════════════════════════════════════════════════════════════════
def draw_agile_model():
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 9)
    ax.axis('off')
    ax.set_title('Figure 1: Agile Development Model Adapted for the Project',
                 fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    sprints = [
        ("Sprint 1\n(Weeks 1-2)", "Project Setup\n& Authentication",
         "Flutter project structure\nFirebase config\nUser auth module", C_SECONDARY),
        ("Sprint 2\n(Weeks 3-4)", "Reporting\nInterface",
         "Scam reporting forms\nForm validation\nEvidence upload", C_TEAL),
        ("Sprint 3\n(Weeks 5-6)", "ML Model\nIntegration",
         "Model training\nNLP pipeline\nScam classification", C_ACCENT),
        ("Sprint 4\n(Weeks 7-8)", "Risk Assessment\n& Notifications",
         "Risk scoring engine\nFirebase Cloud Functions\nPush notifications", C_WARNING),
        ("Sprint 5\n(Weeks 9-10)", "Educational\nResources",
         "Content module\nMultilingual support\n(EN/FR/Pidgin)", C_PURPLE),
        ("Sprint 6\n(Weeks 11-12)", "Testing &\nDeployment",
         "Integration testing\nPerformance optimization\nPilot preparation", C_SUCCESS),
    ]

    box_w = 1.8
    box_h = 1.2
    detail_h = 1.6
    gap = 0.3
    start_x = 0.5
    top_y = 7.0
    detail_y = top_y - box_h - 0.4 - detail_h

    for i, (title, subtitle, details, color) in enumerate(sprints):
        x = start_x + i * (box_w + gap)

        # Sprint box
        rect = FancyBboxPatch((x, top_y - box_h), box_w, box_h,
                               boxstyle="round,pad=0.1", facecolor=color,
                               edgecolor='white', linewidth=2)
        ax.add_patch(rect)
        ax.text(x + box_w/2, top_y - box_h/2 + 0.15, title,
                ha='center', va='center', fontsize=8, fontweight='bold', color='white')
        ax.text(x + box_w/2, top_y - box_h/2 - 0.25, subtitle,
                ha='center', va='center', fontsize=7, color='white')

        # Arrow to next sprint
        if i < 5:
            ax.annotate('', xy=(x + box_w + gap - 0.05, top_y - box_h/2),
                       xytext=(x + box_w + 0.05, top_y - box_h/2),
                       arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))

        # Detail box
        detail_rect = FancyBboxPatch((x, detail_y), box_w, detail_h,
                                      boxstyle="round,pad=0.1", facecolor=C_LIGHT,
                                      edgecolor=color, linewidth=1.5)
        ax.add_patch(detail_rect)
        ax.text(x + box_w/2, detail_y + detail_h/2, details,
                ha='center', va='center', fontsize=6.5, color=C_TEXT, linespacing=1.4)

        # Connecting line
        ax.plot([x + box_w/2, x + box_w/2], [top_y - box_h, detail_y + detail_h],
                color=color, linewidth=1.5, linestyle='--')

    # Feedback loop arrow at bottom
    loop_y = detail_y - 0.8
    ax.annotate('', xy=(start_x + 0.3, loop_y + 0.2),
               xytext=(start_x + 5 * (box_w + gap) + box_w - 0.3, loop_y + 0.2),
               arrowprops=dict(arrowstyle='->', color=C_ACCENT, lw=2,
                              connectionstyle='arc3,rad=0.3'))
    ax.text(start_x + 3 * (box_w + gap), loop_y - 0.15,
            'Continuous Feedback Loop: Review \u2192 Adapt \u2192 Iterate',
            ha='center', va='center', fontsize=9, fontweight='bold',
            color=C_ACCENT, style='italic')

    # Phase labels
    ax.text(start_x + 1.5 * (box_w + gap), top_y + 0.5,
            'DEVELOPMENT PHASE (3 Months)', ha='center', fontsize=10,
            fontweight='bold', color=C_PRIMARY)
    ax.text(start_x + 4.5 * (box_w + gap), top_y + 0.5,
            'TESTING & DEPLOYMENT', ha='center', fontsize=10,
            fontweight='bold', color=C_PRIMARY)

    # Divider line
    div_x = start_x + 3 * (box_w + gap) - gap/2
    ax.plot([div_x, div_x], [top_y + 0.3, detail_y - 0.3],
            color=C_PRIMARY, linewidth=1, linestyle=':')

    # Bottom phase: Pilot Testing
    pilot_y = loop_y - 1.2
    pilot_rect = FancyBboxPatch((2, pilot_y), 10, 0.8,
                                 boxstyle="round,pad=0.1", facecolor='#FADBD8',
                                 edgecolor=C_ACCENT, linewidth=2)
    ax.add_patch(pilot_rect)
    ax.text(7, pilot_y + 0.4,
            'PILOT TESTING PHASE (3 Months): Lagos, Nigeria  &  Douala, Cameroon  |  50-100 Users  |  SUS + Interviews + Analytics',
            ha='center', va='center', fontsize=8.5, fontweight='bold', color=C_ACCENT)

    save_fig(fig, 'fig1_agile_model.png')

draw_agile_model()


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 2: System Architecture Diagram
# ═════════════════════════════════════════════════════════════════════════════
def draw_system_architecture():
    fig, ax = plt.subplots(1, 1, figsize=(14, 10))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 11)
    ax.axis('off')
    ax.set_title('Figure 2: System Architecture Diagram (Three-Tier Client-Server)',
                 fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    # ── Tier 1: Presentation Layer ──
    tier1_y = 8.5
    tier1_rect = FancyBboxPatch((0.5, tier1_y), 13, 2,
                                 boxstyle="round,pad=0.15", facecolor='#D6EAF8',
                                 edgecolor=C_SECONDARY, linewidth=2)
    ax.add_patch(tier1_rect)
    ax.text(7, tier1_y + 1.75, 'PRESENTATION LAYER (Flutter Mobile App)',
            ha='center', fontsize=11, fontweight='bold', color=C_SECONDARY)

    # Client components
    client_items = [
        (1.5, "Scam Reporting\nUI", C_SECONDARY),
        (3.8, "Risk Assessment\nDisplay", C_SECONDARY),
        (6.1, "Educational\nResource Hub", C_SECONDARY),
        (8.4, "User Dashboard\n& History", C_SECONDARY),
        (10.7, "Notifications\n& Alerts", C_SECONDARY),
    ]
    for x, label, color in client_items:
        rect = FancyBboxPatch((x, tier1_y + 0.2), 1.8, 1.0,
                               boxstyle="round,pad=0.08", facecolor=C_WHITE,
                               edgecolor=color, linewidth=1.5)
        ax.add_patch(rect)
        ax.text(x + 0.9, tier1_y + 0.7, label, ha='center', va='center',
                fontsize=7, color=C_TEXT, fontweight='bold')

    # Arrow down
    ax.annotate('', xy=(7, tier1_y - 0.15), xytext=(7, tier1_y + 0.15),
               arrowprops=dict(arrowstyle='<->', color=C_PRIMARY, lw=2.5))
    ax.text(8.5, tier1_y - 0.05, 'REST API + Firestore Real-time Listeners',
            fontsize=8, color=C_PRIMARY, fontstyle='italic')

    # ── Tier 2: Application Logic Layer ──
    tier2_y = 5.2
    tier2_rect = FancyBboxPatch((0.5, tier2_y), 13, 2.8,
                                 boxstyle="round,pad=0.15", facecolor='#D5F5E3',
                                 edgecolor=C_SUCCESS, linewidth=2)
    ax.add_patch(tier2_rect)
    ax.text(7, tier2_y + 2.5, 'APPLICATION LOGIC LAYER (Firebase Cloud Functions)',
            ha='center', fontsize=11, fontweight='bold', color=C_SUCCESS)

    logic_items = [
        (1.2, tier2_y + 1.2, "Auth\nService", C_SUCCESS),
        (3.2, tier2_y + 1.2, "Report\nRouter", C_SUCCESS),
        (5.2, tier2_y + 1.2, "ML Classification\nEngine", C_ACCENT),
        (7.5, tier2_y + 1.2, "Risk Assessment\nComputer", C_WARNING),
        (9.8, tier2_y + 1.2, "Notification\nDispatcher", C_PURPLE),
        (11.8, tier2_y + 1.2, "Content\nManager", C_TEAL),
    ]
    for x, y, label, color in logic_items:
        rect = FancyBboxPatch((x, y), 1.7, 1.0,
                               boxstyle="round,pad=0.08", facecolor=C_WHITE,
                               edgecolor=color, linewidth=1.5)
        ax.add_patch(rect)
        ax.text(x + 0.85, y + 0.5, label, ha='center', va='center',
                fontsize=7, color=C_TEXT, fontweight='bold')

    # ML model callout
    ml_box = FancyBboxPatch((4.5, tier2_y + 0.15), 3.5, 0.7,
                             boxstyle="round,pad=0.08", facecolor='#FADBD8',
                             edgecolor=C_ACCENT, linewidth=1.5, linestyle='--')
    ax.add_patch(ml_box)
    ax.text(6.25, tier2_y + 0.5, 'TensorFlow Lite Model | NLP Pipeline | Category Mapper',
            ha='center', va='center', fontsize=6.5, color=C_ACCENT, fontweight='bold')

    # Arrow down
    ax.annotate('', xy=(7, tier2_y - 0.15), xytext=(7, tier2_y + 0.15),
               arrowprops=dict(arrowstyle='<->', color=C_PRIMARY, lw=2.5))
    ax.text(8.5, tier2_y - 0.05, 'Encrypted Read/Write (TLS 1.2+)',
            fontsize=8, color=C_PRIMARY, fontstyle='italic')

    # ── Tier 3: Data Layer ──
    tier3_y = 2.0
    tier3_rect = FancyBboxPatch((0.5, tier3_y), 13, 2.8,
                                 boxstyle="round,pad=0.15", facecolor='#F9EBEA',
                                 edgecolor=C_ACCENT, linewidth=2)
    ax.add_patch(tier3_rect)
    ax.text(7, tier3_y + 2.5, 'DATA LAYER (Firebase Backend)',
            ha='center', fontsize=11, fontweight='bold', color=C_ACCENT)

    data_items = [
        (1.2, "Cloud Firestore\n(NoSQL Database)\n\nUsers, Reports,\nAssessments,\nResources", '#F5B7B1'),
        (4.5, "Firebase Storage\n(File Storage)\n\nScreenshots,\nMessage Logs,\nEvidence Files", '#FADBD8'),
        (7.8, "Firebase Auth\n(Identity)\n\nEmail/Phone Login,\nOTP, Tokens,\nAccess Control", '#F9EBEA'),
        (11.0, "Firebase Cloud\nMessaging (FCM)\n\nPush Notifications,\nAlerts, Tips", '#FDEDEC'),
    ]
    for x, label, color in data_items:
        rect = FancyBboxPatch((x, tier3_y + 0.2), 2.8, 2.0,
                               boxstyle="round,pad=0.08", facecolor=color,
                               edgecolor=C_ACCENT, linewidth=1)
        ax.add_patch(rect)
        ax.text(x + 1.4, tier3_y + 1.2, label, ha='center', va='center',
                fontsize=7, color=C_TEXT, fontweight='bold', linespacing=1.3)

    # Platforms at bottom
    ax.text(7, 1.5, 'Android 8.0+  |  iOS 13.0+  |  Cross-Platform via Flutter Single Codebase',
            ha='center', fontsize=9, color=C_PRIMARY, fontweight='bold',
            bbox=dict(boxstyle='round,pad=0.3', facecolor=C_LIGHT, edgecolor=C_PRIMARY))

    save_fig(fig, 'fig2_system_architecture.png')

draw_system_architecture()


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 3: Entity Relationship Diagram (ERD)
# ═════════════════════════════════════════════════════════════════════════════
def draw_erd():
    fig, ax = plt.subplots(1, 1, figsize=(15, 10))
    ax.set_xlim(0, 15)
    ax.set_ylim(0, 10.5)
    ax.axis('off')
    ax.set_title('Figure 3: Entity Relationship Diagram (ERD)',
                 fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    def draw_entity(x, y, w, h, title, attributes, pk, fks, color):
        # Title bar
        title_h = 0.5
        title_rect = FancyBboxPatch((x, y + h - title_h), w, title_h,
                                     boxstyle="round,pad=0.05,rounding_size=0.1",
                                     facecolor=color, edgecolor=color, linewidth=2)
        ax.add_patch(title_rect)
        ax.text(x + w/2, y + h - title_h/2, title, ha='center', va='center',
                fontsize=10, fontweight='bold', color='white')

        # Body
        body_rect = FancyBboxPatch((x, y), w, h - title_h,
                                    boxstyle="round,pad=0.05,rounding_size=0.1",
                                    facecolor=C_WHITE, edgecolor=color, linewidth=2)
        ax.add_patch(body_rect)

        line_h = 0.3
        for i, attr in enumerate(attributes):
            ay = y + h - title_h - 0.25 - i * line_h
            prefix = ""
            style = "normal"
            weight = "normal"
            if attr in pk:
                prefix = "PK  "
                weight = "bold"
                style = "normal"
            elif attr in fks:
                prefix = "FK  "
                style = "italic"
            ax.text(x + 0.15, ay, f"{prefix}{attr}", fontsize=7,
                    va='center', color=C_TEXT, fontweight=weight, fontstyle=style)

    # USER entity
    draw_entity(0.5, 6.5, 3, 3.5, "USER",
                ["user_id", "name", "email", "phone", "language_preference",
                 "city", "digital_literacy_level", "registration_date"],
                pk=["user_id"], fks=[], color=C_SECONDARY)

    # SCAM_REPORT entity
    draw_entity(5.5, 6.5, 3, 3.5, "SCAM_REPORT",
                ["report_id", "user_id", "scam_category", "description",
                 "evidence_url", "date_of_incident", "financial_loss",
                 "submission_date", "status"],
                pk=["report_id"], fks=["user_id"], color=C_ACCENT)

    # RISK_ASSESSMENT entity
    draw_entity(10.5, 6.5, 3.5, 3.0, "RISK_ASSESSMENT",
                ["assessment_id", "report_id", "risk_level", "confidence_score",
                 "explanation", "assessment_date"],
                pk=["assessment_id"], fks=["report_id"], color=C_WARNING)

    # EDUCATIONAL_RESOURCE entity
    draw_entity(5.5, 1.0, 3.5, 3.0, "EDUCATIONAL_RESOURCE",
                ["resource_id", "title", "content_type", "scam_category",
                 "language", "url", "publication_date"],
                pk=["resource_id"], fks=[], color=C_SUCCESS)

    # NOTIFICATION entity
    draw_entity(0.5, 1.0, 3.5, 3.0, "NOTIFICATION",
                ["notification_id", "user_id", "message", "type",
                 "sent_date", "read_status"],
                pk=["notification_id"], fks=["user_id"], color=C_PURPLE)

    # ── Relationships ──

    # USER --1:M-- SCAM_REPORT
    ax.annotate('', xy=(5.5, 8.2), xytext=(3.5, 8.2),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))
    ax.text(4.5, 8.45, '1 : M', ha='center', fontsize=9, fontweight='bold',
            color=C_PRIMARY, bbox=dict(boxstyle='round,pad=0.2', facecolor=C_LIGHT, edgecolor=C_PRIMARY))
    ax.text(4.5, 8.0, 'submits', ha='center', fontsize=8, fontstyle='italic', color=C_TEXT)

    # SCAM_REPORT --1:1-- RISK_ASSESSMENT
    ax.annotate('', xy=(10.5, 8.2), xytext=(8.5, 8.2),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))
    ax.text(9.5, 8.45, '1 : 1', ha='center', fontsize=9, fontweight='bold',
            color=C_PRIMARY, bbox=dict(boxstyle='round,pad=0.2', facecolor=C_LIGHT, edgecolor=C_PRIMARY))
    ax.text(9.5, 8.0, 'generates', ha='center', fontsize=8, fontstyle='italic', color=C_TEXT)

    # USER --1:M-- NOTIFICATION
    ax.annotate('', xy=(2.25, 4.0), xytext=(2.25, 6.5),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))
    ax.text(2.75, 5.25, '1 : M', fontsize=9, fontweight='bold',
            color=C_PRIMARY, bbox=dict(boxstyle='round,pad=0.2', facecolor=C_LIGHT, edgecolor=C_PRIMARY))
    ax.text(1.3, 5.25, 'receives', fontsize=8, fontstyle='italic', color=C_TEXT)

    # SCAM_REPORT -- linked to -- EDUCATIONAL_RESOURCE (via scam_category)
    ax.annotate('', xy=(7.0, 4.0), xytext=(7.0, 6.5),
               arrowprops=dict(arrowstyle='-', color=C_PRIMARY, lw=1.5, linestyle='dashed'))
    ax.text(7.6, 5.25, 'M : M\n(via scam_category)', fontsize=7, fontweight='bold',
            color=C_PRIMARY, bbox=dict(boxstyle='round,pad=0.2', facecolor=C_LIGHT, edgecolor=C_PRIMARY))

    # Legend
    ax.text(11, 2.5, 'Legend:', fontsize=9, fontweight='bold', color=C_TEXT)
    ax.text(11, 2.1, 'PK = Primary Key (bold)', fontsize=8, fontweight='bold', color=C_TEXT)
    ax.text(11, 1.7, 'FK = Foreign Key (italic)', fontsize=8, fontstyle='italic', color=C_TEXT)
    ax.text(11, 1.3, '\u2192  = Relationship direction', fontsize=8, color=C_TEXT)
    ax.text(11, 0.9, '--- = Indirect association', fontsize=8, color=C_TEXT)

    save_fig(fig, 'fig3_erd.png')

draw_erd()


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 4: Class Diagram
# ═════════════════════════════════════════════════════════════════════════════
def draw_class_diagram():
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    ax.set_title('Figure 4: Class Diagram', fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    def draw_class(x, y, w, title, attributes, methods, color):
        total_lines = 1 + len(attributes) + len(methods) + 0.5  # +0.5 for divider
        line_h = 0.28
        h = total_lines * line_h + 0.5

        # Title
        title_h = 0.45
        title_rect = FancyBboxPatch((x, y + h - title_h), w, title_h,
                                     boxstyle="square,pad=0.05",
                                     facecolor=color, edgecolor=C_PRIMARY, linewidth=1.5)
        ax.add_patch(title_rect)
        ax.text(x + w/2, y + h - title_h/2, f'\u00AB{title}\u00BB', ha='center', va='center',
                fontsize=9, fontweight='bold', color='white')

        # Attributes section
        attr_h = len(attributes) * line_h + 0.15
        attr_rect = FancyBboxPatch((x, y + h - title_h - attr_h), w, attr_h,
                                    boxstyle="square,pad=0.05",
                                    facecolor=C_WHITE, edgecolor=C_PRIMARY, linewidth=1)
        ax.add_patch(attr_rect)
        for i, attr in enumerate(attributes):
            ax.text(x + 0.1, y + h - title_h - 0.15 - i * line_h, f'- {attr}',
                    fontsize=6.5, va='center', color=C_TEXT, family='monospace')

        # Methods section
        meth_h = len(methods) * line_h + 0.15
        meth_rect = FancyBboxPatch((x, y + h - title_h - attr_h - meth_h), w, meth_h,
                                    boxstyle="square,pad=0.05",
                                    facecolor='#FAFAFA', edgecolor=C_PRIMARY, linewidth=1)
        ax.add_patch(meth_rect)
        for i, meth in enumerate(methods):
            ax.text(x + 0.1, y + h - title_h - attr_h - 0.15 - i * line_h, f'+ {meth}',
                    fontsize=6.5, va='center', color=C_SUCCESS, family='monospace')

        return h

    # ── Service Classes (Top Row) ──

    draw_class(0.3, 7.5, 3.2, "UserService",
               ["auth: FirebaseAuth", "db: Firestore"],
               ["registerUser()", "loginUser()", "updateProfile()", "getLanguagePreference()"],
               C_SECONDARY)

    draw_class(4.0, 7.5, 3.2, "ReportService",
               ["db: Firestore", "storage: FirebaseStorage"],
               ["createReport()", "uploadEvidence()", "getReportHistory()", "updateReportStatus()"],
               C_ACCENT)

    draw_class(7.7, 7.5, 3.5, "ClassificationEngine",
               ["model: ScamModel", "preprocessor: TextPreprocessor", "mapper: CategoryMapper"],
               ["classifyReport()", "loadModel()", "preprocessText()", "getConfidenceScore()"],
               C_WARNING)

    draw_class(11.7, 7.5, 3.8, "RiskAssessmentService",
               ["engine: ClassificationEngine", "db: Firestore"],
               ["generateAssessment()", "calculateRiskLevel()", "formatExplanation()"],
               '#E67E22')

    draw_class(0.3, 3.5, 3.2, "EducationService",
               ["db: Firestore", "cache: Map"],
               ["getResources()", "filterByCategory()", "filterByLanguage()", "searchResources()"],
               C_SUCCESS)

    draw_class(4.0, 3.5, 3.2, "NotificationService",
               ["fcm: FirebaseMessaging", "db: Firestore"],
               ["sendAlert()", "sendTip()", "sendStatusUpdate()", "scheduleNotification()"],
               C_PURPLE)

    # ── Model/Utility Classes (Bottom Row) ──

    draw_class(7.7, 3.0, 3.0, "ScamModel",
               ["tfliteModel: Interpreter", "labels: List<String>"],
               ["predict()", "getTopCategory()", "getConfidence()"],
               '#7F8C8D')

    draw_class(11.0, 3.0, 3.0, "TextPreprocessor",
               ["tokenizer: Tokenizer", "stopwords: Set<String>"],
               ["tokenize()", "removeStopwords()", "vectorize()"],
               '#7F8C8D')

    draw_class(11.0, 0.5, 3.0, "CategoryMapper",
               ["categories: Map<int,String>"],
               ["mapToCategory()", "getDescription()"],
               '#7F8C8D')

    # ── Dependency Arrows ──
    # ReportService --> ClassificationEngine
    ax.annotate('', xy=(7.7, 9.2), xytext=(7.2, 9.2),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=1.5, linestyle='--'))

    # ClassificationEngine --> RiskAssessmentService
    ax.annotate('', xy=(11.7, 9.2), xytext=(11.2, 9.2),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=1.5, linestyle='--'))

    # ClassificationEngine --> ScamModel
    ax.annotate('', xy=(9.2, 5.2), xytext=(9.2, 7.5),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=1.5, linestyle='--'))

    # ClassificationEngine --> TextPreprocessor
    ax.annotate('', xy=(11.0, 4.5), xytext=(11.0, 7.5),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=1.5, linestyle='--'))

    # ClassificationEngine --> CategoryMapper
    ax.annotate('', xy=(12.5, 2.2), xytext=(12.5, 3.0),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=1.5, linestyle='--'))

    # Legend
    ax.text(0.3, 1.5, 'Legend:', fontsize=9, fontweight='bold', color=C_TEXT)
    ax.text(0.3, 1.1, '--\u25B6  Dependency (uses)', fontsize=8, color=C_PRIMARY)
    ax.text(0.3, 0.7, '- attribute : Type   (private)', fontsize=8, color=C_TEXT, family='monospace')
    ax.text(0.3, 0.3, '+ method()           (public)', fontsize=8, color=C_SUCCESS, family='monospace')

    save_fig(fig, 'fig4_class_diagram.png')

draw_class_diagram()


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 5: Use Case Diagram
# ═════════════════════════════════════════════════════════════════════════════
def draw_use_case():
    fig, ax = plt.subplots(1, 1, figsize=(14, 11))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 11.5)
    ax.axis('off')
    ax.set_title('Figure 5: Use Case Diagram',
                 fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    def draw_actor(x, y, label):
        # Stick figure
        head_r = 0.2
        ax.add_patch(plt.Circle((x, y + 1.2), head_r, fill=False, edgecolor=C_PRIMARY, linewidth=2))
        ax.plot([x, x], [y + 1.0, y + 0.5], color=C_PRIMARY, linewidth=2)  # body
        ax.plot([x - 0.3, x, x + 0.3], [y + 0.9, y + 0.75, y + 0.9], color=C_PRIMARY, linewidth=2)  # arms
        ax.plot([x - 0.25, x, x + 0.25], [y + 0.1, y + 0.5, y + 0.1], color=C_PRIMARY, linewidth=2)  # legs
        ax.text(x, y - 0.15, label, ha='center', fontsize=9, fontweight='bold', color=C_PRIMARY)

    def draw_use_case_oval(x, y, text, color=C_LIGHT):
        oval = mpatches.Ellipse((x, y), 3.2, 0.7, facecolor=color,
                                 edgecolor=C_PRIMARY, linewidth=1.5)
        ax.add_patch(oval)
        ax.text(x, y, text, ha='center', va='center', fontsize=8, color=C_TEXT, fontweight='bold')

    # System boundary
    sys_rect = FancyBboxPatch((3, 0.8), 8, 10,
                               boxstyle="round,pad=0.2", facecolor='#F8F9FA',
                               edgecolor=C_PRIMARY, linewidth=2, linestyle='-')
    ax.add_patch(sys_rect)
    ax.text(7, 10.5, 'CyberGuard West Africa System', ha='center',
            fontsize=11, fontweight='bold', color=C_PRIMARY)

    # ── Actors ──
    draw_actor(0.8, 5.5, 'Victim/User')
    draw_actor(13.2, 7.0, 'ML Classification\nSystem')
    draw_actor(13.2, 2.5, 'Administrator/\nResearcher')

    # ── Use Cases ──
    use_cases = [
        (7, 9.8, "Register / Login", '#D6EAF8'),
        (5.5, 8.6, "Submit Scam Report", '#FADBD8'),
        (8.5, 8.6, "Upload Evidence", '#FADBD8'),
        (5.5, 7.3, "View Risk Assessment", '#FEF9E7'),
        (8.5, 7.3, "Classify Scam Type", '#FEF9E7'),
        (5.5, 6.0, "Browse Educational Resources", '#D5F5E3'),
        (8.5, 6.0, "Filter by Category/Language", '#D5F5E3'),
        (7, 4.8, "View Report History", '#D6EAF8'),
        (5.5, 3.6, "Update Language Preference", '#D6EAF8'),
        (8.5, 3.6, "Receive Notifications", '#E8DAEF'),
        (7, 2.0, "Access Analytics Dashboard", '#E8DAEF'),
        (7, 1.2, "Manage Educational Content", '#D5F5E3'),
    ]

    for x, y, text, color in use_cases:
        draw_use_case_oval(x, y, text, color)

    # ── Associations (Victim/User) ──
    user_x = 1.5
    user_cases = [9.8, 8.6, 7.3, 6.0, 4.8, 3.6]
    for uc_y in user_cases:
        target_x = 5.5 if uc_y not in [9.8, 4.8] else 7
        ax.plot([user_x, target_x - 1.6], [6.2, uc_y],
                color=C_PRIMARY, linewidth=1, alpha=0.6)

    # Victim -> Receive Notifications
    ax.plot([user_x, 8.5 - 1.6], [6.2, 3.6], color=C_PRIMARY, linewidth=1, alpha=0.6)

    # ── Associations (ML System) ──
    ax.plot([12.5, 8.5 + 1.6], [7.7, 7.3], color=C_ACCENT, linewidth=1.5, linestyle='--')
    ax.plot([12.5, 8.5 + 1.6], [7.7, 8.6], color=C_ACCENT, linewidth=1.5, linestyle='--')

    # ── Associations (Admin) ──
    ax.plot([12.5, 7 + 1.6], [3.2, 2.0], color=C_PURPLE, linewidth=1.5, linestyle='--')
    ax.plot([12.5, 7 + 1.6], [3.2, 1.2], color=C_PURPLE, linewidth=1.5, linestyle='--')

    # ── Include/Extend relationships ──
    # Submit Scam Report <<include>> Classify Scam Type
    ax.annotate('', xy=(8.5 - 1.5, 7.3 + 0.15), xytext=(5.5 + 1.5, 8.6 - 0.15),
               arrowprops=dict(arrowstyle='->', color=C_ACCENT, lw=1.5, linestyle='--'))
    ax.text(7.8, 8.1, '\u00ABinclude\u00BB', fontsize=7, color=C_ACCENT,
            fontstyle='italic', fontweight='bold', rotation=-30)

    # Submit Scam Report <<extend>> Upload Evidence
    ax.annotate('', xy=(8.5 - 1.2, 8.6), xytext=(5.5 + 1.5, 8.6),
               arrowprops=dict(arrowstyle='->', color=C_TEAL, lw=1.5, linestyle='--'))
    ax.text(7, 8.8, '\u00ABextend\u00BB', fontsize=7, color=C_TEAL,
            fontstyle='italic', fontweight='bold')

    # Browse Resources <<extend>> Filter
    ax.annotate('', xy=(8.5 - 1.4, 6.0), xytext=(5.5 + 1.6, 6.0),
               arrowprops=dict(arrowstyle='->', color=C_TEAL, lw=1.5, linestyle='--'))
    ax.text(7, 6.2, '\u00ABextend\u00BB', fontsize=7, color=C_TEAL,
            fontstyle='italic', fontweight='bold')

    # Classify <<include>> Risk Assessment
    ax.annotate('', xy=(5.5 + 1.5, 7.3), xytext=(8.5 - 1.5, 7.3),
               arrowprops=dict(arrowstyle='->', color=C_ACCENT, lw=1.5, linestyle='--'))
    ax.text(6.4, 7.5, '\u00ABinclude\u00BB', fontsize=7, color=C_ACCENT,
            fontstyle='italic', fontweight='bold')

    save_fig(fig, 'fig5_use_case.png')

draw_use_case()


# ═════════════════════════════════════════════════════════════════════════════
# FIGURE 6: Convergent Parallel Mixed-Methods Design
# ═════════════════════════════════════════════════════════════════════════════
def draw_mixed_methods():
    fig, ax = plt.subplots(1, 1, figsize=(14, 7))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 7.5)
    ax.axis('off')
    ax.set_title('Figure 6: Convergent Parallel Mixed-Methods Design',
                 fontsize=14, fontweight='bold', pad=20, color=C_TEXT)

    # ── Quantitative Strand (Top) ──
    quant_boxes = [
        (0.5, 5.2, 3.0, 1.8, "QUANTITATIVE\nData Collection",
         "\u2022 SUS Questionnaire\n\u2022 ML Model Metrics\n\u2022 Firebase Analytics", C_SECONDARY),
        (4.2, 5.2, 3.0, 1.8, "QUANTITATIVE\nData Analysis",
         "\u2022 Accuracy/Precision/Recall\n\u2022 SUS Score Computation\n\u2022 Descriptive Statistics", C_SECONDARY),
    ]

    # ── Qualitative Strand (Bottom) ──
    qual_boxes = [
        (0.5, 2.0, 3.0, 1.8, "QUALITATIVE\nData Collection",
         "\u2022 Semi-structured Interviews\n\u2022 Open-ended Questions\n\u2022 User Observations", C_SUCCESS),
        (4.2, 2.0, 3.0, 1.8, "QUALITATIVE\nData Analysis",
         "\u2022 Thematic Analysis\n\u2022 (Braun & Clarke, 2006)\n\u2022 Manual Coding", C_SUCCESS),
    ]

    all_boxes = quant_boxes + qual_boxes
    for x, y, w, h, title, content, color in all_boxes:
        rect = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.1",
                               facecolor=color, edgecolor='white', linewidth=2, alpha=0.9)
        ax.add_patch(rect)
        ax.text(x + w/2, y + h - 0.35, title, ha='center', va='center',
                fontsize=9, fontweight='bold', color='white')
        ax.text(x + w/2, y + h/2 - 0.25, content, ha='center', va='center',
                fontsize=7, color='white', linespacing=1.4)

    # Arrows between collection and analysis
    ax.annotate('', xy=(4.15, 6.1), xytext=(3.55, 6.1),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))
    ax.annotate('', xy=(4.15, 2.9), xytext=(3.55, 2.9),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))

    # ── Merge Point ──
    merge_x, merge_y = 8.5, 4.5
    merge_rect = FancyBboxPatch((merge_x - 1.2, merge_y - 1.0), 2.4, 2.0,
                                 boxstyle="round,pad=0.15", facecolor=C_WARNING,
                                 edgecolor='white', linewidth=2)
    ax.add_patch(merge_rect)
    ax.text(merge_x, merge_y + 0.5, 'MERGE &\nCOMPARE', ha='center', va='center',
            fontsize=10, fontweight='bold', color='white')
    ax.text(merge_x, merge_y - 0.3, 'Side-by-side\nComparison', ha='center', va='center',
            fontsize=7, color='white')

    # Arrows to merge
    ax.annotate('', xy=(merge_x - 1.25, merge_y + 0.5), xytext=(7.25, 6.1),
               arrowprops=dict(arrowstyle='->', color=C_SECONDARY, lw=2.5))
    ax.annotate('', xy=(merge_x - 1.25, merge_y - 0.3), xytext=(7.25, 2.9),
               arrowprops=dict(arrowstyle='->', color=C_SUCCESS, lw=2.5))

    # ── Interpretation ──
    interp_x = 11.5
    interp_rect = FancyBboxPatch((interp_x - 1.3, merge_y - 1.2), 2.8, 2.4,
                                  boxstyle="round,pad=0.15", facecolor=C_ACCENT,
                                  edgecolor='white', linewidth=2)
    ax.add_patch(interp_rect)
    ax.text(interp_x + 0.1, merge_y + 0.6, 'INTERPRET\n& REPORT', ha='center', va='center',
            fontsize=10, fontweight='bold', color='white')
    ax.text(interp_x + 0.1, merge_y - 0.4, '\u2022 Findings\n\u2022 Implications\n\u2022 Recommendations',
            ha='center', va='center', fontsize=7, color='white', linespacing=1.3)

    # Arrow merge to interpretation
    ax.annotate('', xy=(interp_x - 1.35, merge_y), xytext=(merge_x + 1.25, merge_y),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2.5))

    # ── Time arrow at bottom ──
    ax.annotate('', xy=(13, 1.0), xytext=(0.5, 1.0),
               arrowprops=dict(arrowstyle='->', color=C_PRIMARY, lw=2))
    ax.text(7, 0.6, 'Concurrent Data Collection  \u2192  Separate Analysis  \u2192  Convergent Interpretation',
            ha='center', fontsize=9, color=C_PRIMARY, fontweight='bold')
    ax.text(7, 0.2, '(Creswell & Plano Clark, 2017)', ha='center', fontsize=8,
            color=C_PRIMARY, fontstyle='italic')

    # "SIMULTANEOUS" label
    ax.text(-0.2, 4.5, 'SIMULTANEOUS', ha='center', fontsize=10, fontweight='bold',
            color=C_PRIMARY, rotation=90,
            bbox=dict(boxstyle='round,pad=0.3', facecolor=C_LIGHT, edgecolor=C_PRIMARY))

    save_fig(fig, 'fig6_mixed_methods.png')

draw_mixed_methods()


print("\nAll 6 diagrams generated successfully!")
print(f"Output directory: {OUTPUT_DIR}")
