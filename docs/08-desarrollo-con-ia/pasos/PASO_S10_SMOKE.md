---
id: PASO_S10_SMOKE
equipo: B+C
bloque: 10
dep: [PASO_S09_01, PASO_S09_02, PASO_S09_03, PASO_S09_05, PASO_S10_01, PASO_S10_02, PASO_S11_05]
siguiente: PASO_S11_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
outputs: []
---

# PASO S9-S10.SMOKE — Validación de Social + OAuth2 + Perfil
**Grupo legacy:** 5 | **Sprint:** S9-S10 | **Equipo:** B+C | **Dificultad:** 🟡 | **Tiempo:** 45 min

## Navegación
← **Anterior:** [PASO_S11_07.md](PASO_S11_07.md)
→ **Siguiente:** [PASO_S11_01](PASO_S11_01.md) — Bot MEDIUM/HARD (extras opcionales)

---

## Qué valida este paso

Las features sociales y de retención del MVP: ligas progresivas, amigos con presencia, noticias, OAuth2 con Google/GitHub y perfil consolidado. La suite E2E/responsive se confirma en GATE 8 con el checklist de S11.

---

## Verificación automatizada

```bash
API="http://localhost:8088"

# 1. Sistema de ligas: tras una partida, ELO actualiza y liga puede cambiar
curl -fs "$API/api/users/me" -H "Authorization: Bearer $TOKEN" | grep -qE '"league":"(BRONCE|PLATA|ORO|DIAMANTE|MAESTRO)"'  # PASS si: liga válida

# 2. Amigos: enviar solicitud, aceptar, ver presencia
curl -fs -X POST "$API/api/friends/request" -H "Authorization: Bearer $TOKEN_A" -d '{"username":"userB"}'   # PASS HTTP 200
curl -fs -X POST "$API/api/friends/accept/1" -H "Authorization: Bearer $TOKEN_B"                            # PASS HTTP 200
curl -fs "$API/api/friends" -H "Authorization: Bearer $TOKEN_A" | grep -q '"presence"'                      # PASS si: tiene presencia

# 3. Presencia online en Redis
docker exec codemon_redis redis-cli get "presence:1" | grep -qE "(ONLINE|IN_GAME|OFFLINE)"  # PASS si: valor válido

# 4. Noticias listadas
curl -fs "$API/api/news?size=5" | grep -q '"title"'                              # PASS si: hay news

# 5. OAuth2 Google: redirect inicia el flujo
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/oauth2/authorization/google")
test "$HTTP" = "302"                                                              # PASS si: redirect 302

# 6. OAuth2 GitHub: redirect inicia el flujo
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$API/oauth2/authorization/github")
test "$HTTP" = "302"                                                              # PASS si: redirect 302

# 7. E2E Playwright: smoke de flujos social + OAuth + perfil
cd ~/codemon/front && npx playwright test --reporter=line                       # PASS si: todos los tests pasan

# 8. Frontend mobile: responsive funciona
# Manual: abrir DevTools en mobile (375x667), recorrer:
# - Login → Launcher → Lobby → Battle Arena → Shop → Profile
# - Verificar que ningún elemento se sale del viewport ni hay scroll horizontal
```

---

## Definition of Done — GATE 6 + GATE 7

- [ ] Los 8 checks pasan
- [ ] Una partida PvP actualiza ELO y promueve/degrada de liga si corresponde
- [ ] Amigos: solicitud → aceptación → presencia online vista por ambos
- [ ] News: admin puede crear post, usuarios lo ven en el feed
- [ ] OAuth2 Google y GitHub: login social termina con JWT válido
- [ ] Perfil consolidado muestra stats, colección, wallet history y partidas recientes
- [ ] Smoke Playwright cubre social, OAuth y profile; la suite completa queda para GATE 8

---

## Si falla un check

| Check | Acción |
|---|---|
| Liga no actualiza tras partida | revisar `LeagueService.recalculateAfterGame()` en PASO_S09_01 |
| Presencia siempre OFFLINE | revisar heartbeat WS en PASO_S09_02 (TTL 90s) |
| OAuth2 redirect no llega a 302 | revisar `application.yml` con client-id y secret válidos |
| E2E Playwright timeout | revisar selectores y `waitFor` en specs |
| Mobile scroll horizontal | revisar utilidades responsive de Tailwind (en mobile usar `w-full` o `grid-cols-1`, y reservar `md:grid-cols-4` / `md:w-1/4` para desktop) |
