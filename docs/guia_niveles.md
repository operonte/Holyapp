# Guía de creación de preguntas por nivel — HolyApp

> **Fuente de verdad** para redactar el banco de preguntas. Toda pregunta nueva
> (o revisión) debe cumplir las **reglas globales** y ajustarse a los **temas**
> definidos por nivel más abajo. Cuando se generen preguntas para un nivel, se
> consulta primero esta guía.

---

## Reglas globales (formato técnico)

Cada pregunta es un objeto JSON dentro de `assets/questions/<nivel>.json`, bajo
la clave `"questions"`, con esta forma exacta:

```json
{
  "id": "ent-0001",
  "text": "¿...?",
  "options": ["A", "B", "C", "D"],
  "correctIndex": 0,
  "difficulty": "entrada",
  "references": ["Juan 3:16"]
}
```

- **`id`**: prefijo del nivel + número de 4 dígitos correlativo. Prefijos:
  - `entrada` → `ent` · `basico` → `bas` · `medio` → `med`
  - `avanzado` → `ava` · `pastorado` → `pas` · `teologia` → `teo`
  - `evangelista` → `evg`
  - Ejemplos: `ent-0001`, `med-0007`, `teo-0123`, `evg-0001`.
- **`text`**: una sola pregunta, clara y autocontenida.
- **`options`**: EXACTAMENTE 4. Una correcta y tres distractores plausibles.
- **`correctIndex`**: 0–3, posición de la opción correcta dentro de `options`.
  Varía la posición entre preguntas (no dejar siempre la correcta en la misma).
- **`difficulty`**: debe coincidir con el nivel del archivo
  (`entrada` | `basico` | `medio` | `avanzado` | `pastorado` | `teologia` |
  `evangelista`). **Este campo —no el `id`— es el que determina los puntos**.
- **`references`**: de **1 a 3** de respaldo (texto). Normalmente citas bíblicas
  (p. ej. `"Romanos 3:28"`). Dos excepciones permitidas:
  - En **Teología**, temas académicos sin versículo directo citan el pasaje que
    el tema analiza.
  - En **Evangelista**, las preguntas de autores/dichos/avivamientos usan la
    **atribución de la fuente** (p. ej. `"Leonard Ravenhill, 'Why Revival
    Tarries'"`) y, cuando aplique, suman un versículo.
  Deben justificar la respuesta correcta.
- **Unicidad del `id`:** cada `id` debe ser único en **todo el banco** (no solo
  dentro de un nivel), porque en modo cascada un test mezcla varios niveles y el
  `id` se usa como clave para el puntaje y el historial. El prefijo por nivel +
  número correlativo lo garantiza.
- Sin preguntas duplicadas (mismo contenido) dentro de un nivel.

## Valor en puntos por nivel

| Nivel             | `difficulty` | Puntos por acierto* |
|-------------------|--------------|---------------------|
| Nivel de entrada  | `entrada`    | 1                   |
| Básico            | `basico`     | 1                   |
| Medio             | `medio`      | 2                   |
| Avanzado          | `avanzado`   | 2                   |
| Pastorado         | `pastorado`  | 3                   |
| Teología          | `teologia`   | 4                   |
| Evangelista       | `evangelista`| 5                   |

\* Solo se otorgan al acertar **al primer intento**. Acceso en cascada: estar en
el nivel N habilita jugar (y mezclar) los niveles 1…N (Evangelista, el más alto,
habilita los 7).

---

## Temas por nivel

Cada nivel tiene **400 preguntas**.

> **Eje transversal (presente en TODOS los niveles):** _El Corazón Quebrantado y
> la Oración_. En cada nivel debe haber preguntas de este eje, con la
> profundidad propia del nivel.

### 1. Nivel de entrada (`entrada` · 1 pt)

**Enfoque:** Fundamentos prácticos del discipulado, valores del Reino y las
historias bíblicas más universales.

- **Enfoque en Cristo:** No fijarse en las fallas o errores de las personas o
  líderes, sino poner la mirada únicamente en Jesús (Hebreos 12:2; Pedro mirando
  las olas).
- **El Perdón y la Reconciliación:** La necesidad absoluta de perdonar al
  prójimo para recibir el perdón de Dios (Mateo 6:14-15; parábola del siervo
  despiadado).
- **Misericordia y Compasión:** Priorizar la misericordia sobre el juicio y la
  condena legalista (Lucas 6:36; el juicio a la mujer adúltera).
- **El Corazón Quebrantado y la Oración (Eje Transversal):** La oración sincera
  como el motor diario de la fe y el entendimiento de que Dios no rechaza un
  corazón contrito y humillado (Salmo 51:17; la oración del publicano vs. el
  fariseo).
- **El Gran Mandamiento:** Amar a Dios sobre todas las cosas y al prójimo como a
  uno mismo (Mateo 22:37-39; la parábola del Buen Samaritano).
- **Historias Universales:** El Arca de Noé, la Creación, Moisés y las plagas,
  David y Goliat, Daniel en el foso de los leones, el nacimiento y milagros
  públicos de Jesús.
- **Temas adicionales:** el fruto del Espíritu (Gálatas 5:22-23), los Diez
  Mandamientos, la vida y milagros de Jesús, y héroes de la fe sencillos
  (Hebreos 11).

### 2. Básico (`basico` · 1 pt)

**Enfoque:** Estructura general de las Escrituras, datos textuales explícitos,
geografía e historias lineales.

- **Estructura y Canon:** Los 66 libros de la Biblia, la división entre el
  Antiguo y Nuevo Testamento, bloques principales (Pentateuco, Profetas,
  Evangelios, Epístolas).
- **Líderes de Israel:** El periodo de los Jueces (Sansón, Gedeón, Débora) y los
  primeros Reyes de la monarquía unida (Saúl, David, Salomón).
- **El Corazón Quebrantado y la Oración (Eje Transversal):** Ejemplos básicos de
  oraciones contestadas debido a la humildad y desesperación piadosa (la oración
  de Ana por un hijo, el clamor de los israelitas en Egipto).
- **Enseñanzas de Jesús:** Las parábolas del Reino (el sembrador, la semilla de
  mostaza), el Sermón del Monte y las Bienaventuranzas.
- **La Iglesia Primitiva:** Los Hechos de los Apóstoles, la conversión de Saulo
  de Tarso y el inicio de los viajes misioneros.
- **Geografía General:** Ubicación de lugares clave como Jerusalén, el río
  Jordán, Egipto, Nazaret y el Mar de Galilea.
- **Temas adicionales:** los 12 apóstoles, las 12 tribus de Israel, los
  patriarcas (Abraham, Isaac, Jacob, José), cuáles son las cartas de Pablo y los
  libros poéticos/sapienciales (Salmos, Proverbios, Job).

### 3. Medio (`medio` · 2 pts)

**Enfoque:** Libros menos frecuentados, profecías del Antiguo Testamento, leyes
levíticas y el Reino dividido.

- **El Reino Dividido:** La separación de Israel (Norte) y Judá (Sur), reyes
  reformadores (Josías, Ezequías) y reyes idólatras (Acab, Manasés).
- **Profetas Mayores y Menores:** El contexto histórico de Isaías y Jeremías, y
  las temáticas específicas de profetas como Oseas, Amós, Jonás y Miqueas.
- **El Corazón Quebrantado y la Oración (Eje Transversal):** La oración de
  intercesión y los salmos de lamentación (David arrepentido tras su pecado en el
  Salmo 32 y 51, la oración de Daniel confesando los pecados de su nación).
- **Leyes y Tabernáculo:** El diseño del Tabernáculo en el desierto, el sistema
  de sacrificios de Levítico y las 7 fiestas solemnes obligatorias (Pascua,
  Pentecostés, Tabernáculos).
- **Epístolas Generales:** Los argumentos prácticos de las cartas de Santiago, 1
  y 2 de Pedro, las cartas de Juan y la epístola de Judas.
- **Temas adicionales:** el cautiverio y el retorno (Esdras y Nehemías), la
  tipología (sombras de Cristo en el AT), los dones y los libros históricos.

### 4. Avanzado (`avanzado` · 2 pts)

**Enfoque:** Contexto histórico-cultural de los imperios, introducción a los
idiomas originales y conexiones teológicas profundas.

- **Idiomas Originales:** Palabras e ideas clave del hebreo bíblico (Hesed,
  Shalom, Elohim), arameo y griego koiné (Ágape, Logos, Charis).
- **Epístolas Profundas (Romanos y Hebreos):** La doctrina de la justificación
  por la fe, la soberanía de Dios, el sacerdocio eterno de Melquisedec y la
  superioridad del Nuevo Pacto.
- **El Corazón Quebrantado y la Oración (Eje Transversal):** La teología de la
  oración en el Nuevo Testamento (Jesús orando en Getsemaní con sudor de sangre,
  el Espíritu Santo intercediendo por nosotros con gemidos indecibles en Romanos
  8:26).
- **Periodo Intertestamentario:** Los 400 años de silencio entre Malaquías y
  Mateo, el impacto del Imperio Griego (helenización) y la revuelta de los
  Macabeos.
- **Escatología Introductoria:** El simbolismo profético y las visiones
  apocalípticas en los libros de Daniel, Ezequiel y las cartas a las 7 iglesias
  en Apocalipsis.
- **Temas adicionales:** doctrinas (santificación, adopción), el contexto
  grecorromano del Nuevo Testamento, la antropología bíblica y los dones
  espirituales (1 Corintios 12).

### 5. Pastorado (`pastorado` · 3 pts)

**Enfoque:** Eclesiología corporativa, administración de la iglesia local,
consejería bíblica y teología de los pactos.

- **Epístolas Pastorales:** Requisitos y calificaciones bíblicas para los roles
  de ancianos (pastores/obispos) y diáconos detallados en 1 y 2 Timoteo y Tito.
- **Gobierno Eclesiástico y Orden:** El modelo de disciplina eclesiástica (Mateo
  18), la resolución de conflictos doctrinales en el Concilio de Jerusalén
  (Hechos 15) y la administración del Bautismo y la Cena del Señor.
- **El Corazón Quebrantado y la Oración (Eje Transversal):** La vida de oración
  del líder (Pablo orando de rodillas por las iglesias en Efesios, el llanto
  pastoral por el rebaño, mantener un espíritu quebrantado para evitar el orgullo
  del ministerio).
- **Teología de los Pactos:** El progreso y cumplimiento de los pactos divinos a
  lo largo de la historia de la salvación (Pacto Adámico, Noéico, Abrahámico,
  Mosaico, Davídico y el Nuevo Pacto).
- **Cuidado Pastoral:** Consejería basada estrictamente en las Escrituras, la
  restauración del caído con espíritu de mansedumbre (Gálatas 6:1) y la defensa
  contra falsas doctrinas locales.
- **Apologética (defensa interna):** Fundamentar y defender la sana doctrina
  ante el error dentro de la iglesia (Tito 1:9; 1 Pedro 3:15).
- **Vida y administración pastoral:** Vida devocional y ética del pastor,
  administración de la iglesia local, finanzas/mayordomía, organización del
  ministerio y administración de los coros y la música de la iglesia.
- **Predicación y homilética:** Técnicas de predicación, preparación y
  estructura del sermón, exposición fiel del texto (2 Timoteo 4:2).
- **Estoicismo (contexto y contraste):** El pensamiento estoico del mundo del
  Nuevo Testamento y su contraste con la fe cristiana (Hechos 17:18).
- **Disciplinas varias del pastor:** Las áreas que un pastor debe dominar
  (discipulado, liderazgo, manejo de conflictos, misiones, familia ministerial).

### 6. Teología (`teologia` · 4 pts)

**Enfoque:** Historia de la iglesia, hermenéutica crítica, análisis de fuentes
del Pentateuco, concilios y métodos modernos.

- **Las 4 Corrientes de Escritura (Hipótesis Documental):** Análisis y
  diferenciación de las fuentes tradicionales que componen el Pentateuco: Yavista
  (J), Elohísta (E), Deuteronomista (D) y Sacerdotal (P).
- **Métodos de Análisis Modernos y "Crítica de la Sospecha":** Introducción a la
  hermenéutica de la sospecha aplicada al texto (análisis de las estructuras de
  poder, contextos económicos e ideologías políticas detrás de las redacciones y
  traducciones históricas).
- **Las Mujeres en la Biblia:** Exégesis y rol teológico de figuras clave
  (Débora como jueza, Ester como salvadora política, Rut, Priscila como maestra,
  Febe como diaconisa, y las mujeres como primeras testigos de la resurrección en
  un contexto patriarcal).
- **El Corazón Quebrantado y la Oración (Eje Transversal Avanzado):** La relación
  indisoluble entre la alta academia y la piedad espiritual (la oración
  contemplativa, el peligro del intelectualismo estéril y el concepto
  agustiniano/reformado de que 'la verdadera teología se hace de rodillas').
- **Historia de los Concilios Ecuménicos:** Los debates teológicos en el Concilio
  de Nicea (325 d.C.), Constantinopla, Éfeso y Calcedonia respecto a la Trinidad
  y la Cristología.
- **Teología Sistemática y Crítica Textual:** Estudio de la Soteriología,
  Pneumatología, variantes textuales en manuscritos antiguos (Codex Sinaiticus,
  Vaticanus) y confiabilidad del canon.
- **Idiomas originales (vocabulario y gramática):** Vocabulario de hebreo bíblico
  y griego koiné; el alefato hebreo y el alfabeto griego; reglas básicas,
  declinaciones y casos; nociones de gramática de ambos idiomas.
- **Exégesis y hermenéutica:** Principios de interpretación, contexto,
  géneros literarios y método exegético.
- **Historia de la iglesia e historia de Israel:** Grandes periodos y figuras de
  la historia eclesiástica y de Israel.
- **Investigación científica y arqueología bíblica:** Método histórico,
  datación, hallazgos arqueológicos y la relación entre ciencia y fe.
- **Historia de los pueblos del entorno bíblico:** Mesopotamia, Egipto, Canaán,
  Grecia y Roma, y su influencia en el texto.
- **Ediciones críticas y manuscritos:** La Biblia Hebraica Stuttgartensia
  (hebreo), el Nuevo Testamento Nestle-Aland (griego), y los distintos
  rollos/manuscritos.
- **Canon y libros:** Libros canónicos, deuterocanónicos y apócrifos (qué son,
  cuáles son y por qué el canon protestante difiere; enfoque informativo).
- **Corrientes y autores:** Corrientes de filosofía, teosofía y filología, y los
  nombres de autores y teólogos clave.
- **Estoicismo:** Como corriente filosófica del mundo del NT y su contraste con
  el evangelio (Hechos 17:18).

### 7. Evangelista (`evangelista` · 5 pts) — "Avivamiento, poder y acción"

**Enfoque:** Nivel *capstone* (el más alto). Consolida y repasa todo lo
aprendido y lo dirige a la ACCIÓN, con énfasis principal en el avivamiento, la
oración y el poder del Espíritu. Inspirado en los grandes hombres y mujeres de
la fe a través de la historia.

> **Referencias en este nivel:** las preguntas de autores, dichos, oraciones y
> avivamientos usan la **fuente** (autor/obra/evento) como referencia, y suman un
> versículo cuando aplique. **Solo usar citas/oraciones bien documentadas**: no
> inventar ni atribuir mal.

- **Autores y predicadores del avivamiento (dichos y oraciones):** Leonard
  Ravenhill, David Wilkerson, Jonathan Edwards, George Whitefield, John Wesley,
  Charles Finney, D.L. Moody, Charles Spurgeon, A.W. Tozer, Andrew Murray,
  E.M. Bounds, George Müller, William Booth, Smith Wigglesworth, Hudson Taylor,
  William Carey, Jim Elliot, Corrie ten Boom, Evan Roberts.
- **Avivamientos históricos:** el Gran Despertar (Edwards/Whitefield), el
  Avivamiento de Gales de 1904 (Evan Roberts), la Calle Azusa (1906) y el
  Avivamiento de las Hébridas.
- **Teología y práctica del poder (eje transversal en su clímax):** la oración
  intercesora, el ayuno, el clamor, la dependencia del Espíritu Santo y el
  avivamiento personal.
- **Acción:** evangelismo personal y masivo, misionología, la Gran Comisión y el
  kerygma, métodos de evangelización, manejo de objeciones, evangelismo
  transcultural, apologética aplicada (ante incrédulos), discipulado de nuevos
  creyentes y plantación de iglesias.

**Reparto sugerido:** la mayoría de las preguntas en avivamiento/oración/poder y
autores (bloques 1–3); el resto en acción/evangelismo (bloque 4) y repaso de los
niveles previos.
