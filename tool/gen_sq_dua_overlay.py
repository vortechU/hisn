# -*- coding: utf-8 -*-
"""Build the Albanian overlay from project drafts and exact Quran excerpts.

The hadith prose below is original project translation of the existing bundled
Arabic/English content, pending qualified Albanian and religious review. It is
not attributed to a published translator. Quran wording belongs to Hasan Efendi
Nahi and comes verbatim from the bundled Tanzil sq.nahi edition.

Run from the project root: python -X utf8 tool/gen_sq_dua_overlay.py
"""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BASE_SHA256 = 'cf5427dc6b3dfc5dc6440ea7770f5f887afab67434d0f669cb1ccf53919f41a7'
QURAN_CREDIT = 'Përkthimi i pjesës kuranore: Hasan Efendi Nahi'

# Shared suffixes use the same wording in morning/evening and other categories.
FORMULAS = {
    'radeetu': ('Jam i kënaqur me Allahun si Zot', 'Jam i kënaqur me Allahun si Zotin tim, me Islamin si fenë time dhe me Muhamedin ﷺ si Profetin tim.'),
    'bismillah_la_yadurr': ('Me emrin e Allahut, me të cilin asgjë nuk dëmton', 'Me emrin e Allahut, me emrin e të Cilit asgjë në tokë e as në qiell nuk mund të bëjë dëm. Ai dëgjon dhe di gjithçka.'),
    'subhanallah_adada': ('Lavdërimi i Allahut sa numri i krijesave të Tij', 'I Lartësuar është Allahu dhe Atij i takon lavdërimi, sa numri i krijesave të Tij, aq sa është kënaqësia e Tij, sa pesha e Fronit të Tij dhe sa boja e fjalëve të Tij.'),
    'ushhiduka': ('Marrja e Allahut për dëshmitar (katër herë)', None),
    'asbahna': ('E arritëm mëngjesin', 'E arritëm mëngjesin dhe i gjithë sundimi i përket Allahut. Të gjitha lavdërimet i takojnë Allahut. Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi, dhe Ai është i Plotfuqishëm për çdo gjë.'),
    'bika_asbahna': ('Me Ty e arrijmë mëngjesin', 'O Allah, me Ty e arrijmë mëngjesin dhe me Ty e arrijmë mbrëmjen. Me Ty jetojmë dhe me Ty vdesim, dhe tek Ti është ringjallja.'),
    'fitrah': ('Në natyrshmërinë e Islamit', None),
    'ya_hayyu': ('O i Përjetshëm, o Mbajtës i gjithçkaje', 'O i Përjetshëm, o Mbajtës i gjithçkaje, me mëshirën Tënde kërkoj ndihmë. M’i rregullo të gjitha çështjet dhe mos më lër t’i mbështetem vetes as sa hap e mbyll sytë.'),
    'ma_asbaha_nimah': ('Mirënjohja për mirësitë e Allahut', None),
    'ma_amsa_nimah': ('Mirënjohja për mirësitë e Allahut', None),
    'salah_nabi': ('Salavate mbi Profetin ﷺ (dhjetë herë)', 'O Allah, dërgo bekimet dhe paqen Tënde mbi Profetin tonë Muhamed.'),
    'sayyidul_istighfar': ('Lutja më e lartë për kërkimin e faljes', 'O Allah, Ti je Zoti im. Nuk ka të adhuruar me të drejtë përveç Teje. Ti më krijove dhe unë jam robi Yt. I përmbahem besëlidhjes dhe premtimit që të kam dhënë sa të mundem. Kërkoj mbrojtjen Tënde nga e keqja që kam bërë. I pranoj mirësitë e Tua ndaj meje dhe e pranoj gjynahun tim. Prandaj më fal, sepse askush përveç Teje nuk i fal gjynahet.'),
    'afiyah': ('Kërkimi i mirëqenies', 'O Allah, më jep shëndet në trupin tim. O Allah, më jep shëndet në dëgjimin tim. O Allah, më jep shëndet në shikimin tim. Nuk ka të adhuruar me të drejtë përveç Teje. O Allah, kërkoj mbrojtjen Tënde nga mosbesimi dhe varfëria, dhe kërkoj mbrojtjen Tënde nga dënimi i varrit. Nuk ka të adhuruar me të drejtë përveç Teje.'),
    'afwa_afiyah': ('Kërkimi i faljes dhe i sigurisë nga Allahu', 'O Allah, të kërkoj falje dhe mirëqenie në këtë jetë dhe në tjetrën. O Allah, të kërkoj falje dhe mirëqenie në fenë time, në çështjet e mia të kësaj bote, në familjen dhe pasurinë time. O Allah, m’i mbulo të metat dhe m’i qetëso frikërat. O Allah, më ruaj përpara dhe prapa, djathtas dhe majtas, dhe nga lart. Me madhështinë Tënde kërkoj mbrojtje që të mos më përpijë toka papritur nga poshtë.'),
    'alimal_ghayb': ('Njohësi i së fshehtës', 'O Allah, Njohës i së fshehtës dhe i së dukshmes, Krijues i qiejve dhe i tokës, Zot dhe Sundues i çdo gjëje! Dëshmoj se nuk ka të adhuruar me të drejtë përveç Teje. Kërkoj mbrojtjen Tënde nga e keqja e vetes sime, nga e keqja e shejtanit dhe nxitja e tij për të të bërë ortak, dhe që të mos i shkaktoj të keqe vetes apo ndonjë muslimani.'),
    'tahlil_100': ('Pohimi i njëshmërisë së Allahut (100 herë)', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi, dhe Ai është i Plotfuqishëm për çdo gjë.'),
    'subhanallah_bihamdihi': ('Lavdërimi i Allahut (100 herë)', 'I Lartësuar është Allahu dhe Atij i takon i gjithë lavdërimi.'),
    'audhu_kalimat': ('Mbrojtja me fjalët e përsosura të Allahut', 'Kërkoj mbrojtje me fjalët e përsosura të Allahut nga e keqja e gjithçkaje që Ai ka krijuar.'),
    'amsayna': ('E arritëm mbrëmjen', 'E arritëm mbrëmjen dhe i gjithë sundimi i përket Allahut. Të gjitha lavdërimet i takojnë Allahut. Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi, dhe Ai është i Plotfuqishëm për çdo gjë.'),
    'bika_amsayna': ('Me Ty e arrijmë mbrëmjen', 'O Allah, me Ty e arrijmë mbrëmjen dhe me Ty e arrijmë mëngjesin. Me Ty jetojmë dhe me Ty vdesim, dhe tek Ti është kthimi përfundimtar.'),
    'istighfar_salam': ('Kërkimi i faljes dhe i paqes', 'I kërkoj falje Allahut (tri herë). O Allah, Ti je Paqja dhe prej Teje vjen paqja. I bekuar je Ti, o Zotërues i madhështisë dhe i nderimit.'),
    'tahlil': ('Pohimi i njëshmërisë së Allahut', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi, dhe Ai është i Plotfuqishëm për çdo gjë. O Allah, askush nuk mund ta ndalë atë që Ti jep dhe askush nuk mund ta japë atë që Ti ndal. As pasuria dhe as pozita nuk i bëjnë dobi askujt kundrejt Teje, sepse prej Teje vjen çdo pasuri dhe pozitë.'),
    'la_ilaha_wahdahu': ('Përkushtimi i sinqertë pas sabahut dhe akshamit', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi. Ai jep jetë dhe shkakton vdekjen, dhe Ai është i Plotfuqishëm për çdo gjë. Nuk ka forcë e as fuqi përveçse me Allahun. Nuk ka të adhuruar me të drejtë përveç Allahut dhe vetëm Atë e adhurojmë. Atij i përket mirësia, dhuntia dhe lavdërimi më i mirë. Nuk ka të adhuruar me të drejtë përveç Allahut. Vetëm Atij ia kushtojmë adhurimin me sinqeritet, edhe nëse mosbesimtarët e urrejnë këtë.'),
    'subhanallah': ('I Lartësuar është Allahu', 'I Lartësuar është Allahu.'),
    'alhamdulillah': ('Të gjitha lavdërimet i takojnë Allahut', 'Të gjitha lavdërimet i takojnë Allahut.'),
    'allahu_akbar': ('Allahu është më i Madhi', 'Allahu është më i Madhi.'),
    'tasbih_tahlil_final': ('Plotësimi i njëqind përsëritjeve pas namazit', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi, dhe Ai është i Plotfuqishëm për çdo gjë.'),
    'ilman_nafian': ('Dija e dobishme pas sabahut', 'O Allah, të kërkoj dije të dobishme, furnizim të mirë dhe vepra të pranuara.'),
    'bismika': ('Me emrin Tënd vdes dhe jetoj', 'Me emrin Tënd, o Allah, vdes dhe jetoj.'),
    'qini': ('Më mbro nga dënimi Yt', 'O Allah, më mbro nga dënimi Yt ditën kur do t’i ringjallësh robërit e Tu.'),
    'tasbih_fatima': ('Tesbihu para gjumit (tesbihu i Fatimes)', 'I Lartësuar është Allahu (33 herë). Të gjitha lavdërimet i takojnë Allahut (33 herë). Allahu është më i Madhi (34 herë).'),
    'night_fear': ('Kur trembesh ose frikësohesh natën', 'Kërkoj mbrojtje me fjalët e përsosura të Allahut nga zemërimi dhe dënimi i Tij, nga e keqja e robërve të Tij, nga ngacmimet e shejtanëve dhe nga prania e tyre.'),
    'aslamtu': ('Ty të dorëzohem', 'O Allah, Ty të dorëzohem, Ty t’i besoj çështjet e mia, drejt Teje e kthej fytyrën dhe tek Ti mbështetem, duke shpresuar tek Ti dhe duke të pasur frikë. Nuk ka strehë e as shpëtim prej Teje përveçse tek Ti. Besoj në Librin që Ti ke shpallur dhe në Profetin që Ti ke dërguar.'),
    'alhamdulillah_ahyana': ('Lavdërimi i Allahut që na dha jetë', 'Të gjitha lavdërimet i takojnë Allahut që na dha jetë pasi na e kishte marrë, dhe tek Ai është ringjallja.'),
    'afani': ('Lavdërimi i Allahut që ma ktheu shpirtin', 'Të gjitha lavdërimet i takojnë Allahut që ma ktheu shëndetin, ma ktheu shpirtin dhe më lejoi ta përmend Atë.'),
    'before_eating': ('Para ushqimit', 'Me emrin e Allahut. Nëse harron në fillim, thuaj: Bismilahi evvelehu ve ahirahu — Me emrin e Allahut në fillim dhe në fund të tij.'),
    'after_eating': ('Pas ushqimit', 'Të gjitha lavdërimet i takojnë Allahut që më ushqeu me këtë dhe ma dhuroi, pa ndonjë fuqi apo mundësi nga ana ime.'),
    'leaving_home': ('Dalja nga shtëpia', 'Me emrin e Allahut. Tek Allahu mbështetem. Nuk ka forcë e as fuqi përveçse me Allahun.'),
    'leaving_home_protection': ('Mbrojtja kur del nga shtëpia', 'O Allah, kërkoj mbrojtjen Tënde që të mos devijoj e as të më devijojnë, të mos rrëshqas e as të më bëjnë të rrëshqas, të mos i bëj padrejtësi dikujt e as të më bëhet padrejtësi, dhe të mos sillem me padituri e as të sillen ndaj meje me padituri.'),
    'entering_bathroom': ('Hyrja në nevojtore', 'O Allah, kërkoj mbrojtjen Tënde nga shejtanët meshkuj dhe femra.'),
    'leaving_bathroom': ('Dalja nga nevojtorja', 'Të kërkoj falje.'),
    'entering_home': ('Hyrja në shtëpi', 'O Allah, të kërkoj të mirën e hyrjes dhe të mirën e daljes. Me emrin e Allahut hyjmë dhe me emrin e Allahut dalim. Tek Allahu, Zoti ynë, mbështetemi.'),
    'wearing_clothes': ('Veshja e një rrobe', 'Lavdërimi i takon Allahut që më veshi me këtë rrobë dhe ma dhuroi, pa ndonjë fuqi apo mundësi nga ana ime.'),
    'wearing_new_clothes': ('Veshja e rrobave të reja', 'O Allah, Ty të takon lavdërimi. Ti më veshe me këtë. Të kërkoj të mirën e saj dhe të mirën për të cilën është bërë. Kërkoj mbrojtjen Tënde nga e keqja e saj dhe nga e keqja për të cilën është bërë.'),
    'marketplace': ('Hyrja në treg', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak. Atij i përket sundimi dhe lavdërimi. Ai jep jetë dhe shkakton vdekjen. Ai është i Përjetshmi që nuk vdes. Në dorën e Tij është çdo e mirë, dhe Ai është i Plotfuqishëm për çdo gjë.'),
    'anger': ('Kur zemërohesh', 'Kërkoj mbrojtje tek Allahu nga shejtani i mallkuar.'),
    'jazakallah_khayr': ('Falënderimi i atij që të ka bërë mirë', 'Allahu të shpërbleftë me të mira.'),
    'seeing_afflicted': ('Kur sheh dikë të sprovuar', 'Të gjitha lavdërimet i takojnë Allahut që më ka ruajtur nga ajo me të cilën të ka sprovuar ty dhe më ka dhënë epërsi të madhe ndaj shumë prej krijesave të Tij.'),
    'astaghfirullah_azim': ('Kërkimi i faljes që shlyen gjynahet', 'I kërkoj falje Allahut të Madhërishëm, përveç të Cilit nuk ka të adhuruar me të drejtë, të Përjetshmit, Mbajtësit të gjithçkaje, dhe pendohem tek Ai.'),
    'rabbi_ghfirli': ('O Zoti im, më fal', 'O Zoti im, më fal dhe ma prano pendimin. Ti je Ai që e pranon shumë pendimin, Mëshirëploti.'),
    'hamm_hazan': ('Mbrojtja nga brenga dhe pikëllimi', 'O Allah, kërkoj mbrojtjen Tënde nga brenga dhe pikëllimi, nga paaftësia dhe përtacia, nga koprracia dhe frika, nga rëndesa e borxhit dhe nga nënshtrimi prej njerëzve.'),
    'karb': ('Lutja në vështirësi', 'Nuk ka të adhuruar me të drejtë përveç Allahut, të Madhërishmit, të Butit. Nuk ka të adhuruar me të drejtë përveç Allahut, Zotit të Fronit të Madh. Nuk ka të adhuruar me të drejtë përveç Allahut, Zotit të qiejve, Zotit të tokës dhe Zotit të Fronit Fisnik.'),
    'rahmataka_arju': ('Te mëshira Jote e vendos shpresën', 'O Allah, te mëshira Jote e vendos shpresën. Mos më lër t’i mbështetem vetes as sa hap e mbyll sytë. M’i rregullo të gjitha çështjet. Nuk ka të adhuruar me të drejtë përveç Teje.'),
    'debt': ('Për lehtësim nga borxhi', 'O Allah, më mjafto me atë që ke lejuar, që të mos kem nevojë për atë që ke ndaluar. Me mirësinë Tënde më bëj të pavarur nga çdokush përveç Teje.'),
    'against_oppressor': ('Përballë një shtypësi ose armiku të frikshëm', 'O Allah, Ty të vëmë përballë tyre dhe kërkojmë mbrojtjen Tënde nga të këqijat e tyre.'),
    'stopping': ('Ndalimi në një vend', 'Kërkoj mbrojtje me fjalët e përsosura të Allahut nga e keqja e gjithçkaje që Ai ka krijuar.'),
    'entering_town': ('Hyrja në një qytet ose fshat', 'O Allah, të kërkoj të mirën e tij, të mirën e banorëve të tij dhe të mirën që ndodhet në të. Kërkoj mbrojtjen Tënde nga e keqja e tij, e keqja e banorëve të tij dhe e keqja që ndodhet në të.'),
    'ascending_descending': ('Ngjitja dhe zbritja gjatë udhëtimit', 'Sahabët thoshin tekbirin (Allahu ekber) kur rruga ngjitej dhe tesbihun (Subhanallah) kur rruga zbriste.'),
    'astawdiuka': ('Përcjellja e udhëtarit', 'Allahut ia besoj fenë tënde, amanetin tënd dhe veprat e fundit të jetës sate.'),
    'adhan_testimony': ('Dëshmia gjatë dëgjimit të ezanit', 'Edhe unë dëshmoj se nuk ka të adhuruar me të drejtë përveç Allahut, të Vetëm e pa ortak, dhe se Muhamedi është robi dhe i Dërguari i Tij. Jam i kënaqur me Allahun si Zotin tim, me Muhamedin si të Dërguar dhe me Islamin si fenë time.'),
    'adhan_response_hayya': ('Përgjigjja ndaj thirrjes për namaz', 'Nuk ka forcë e as fuqi përveçse me Allahun.'),
    'after_adhan_salawat': ('Salavatet mbi Profetin pas ezanit', 'O Allah, bekoje Muhamedin dhe familjen e Muhamedit, ashtu siç e bekove familjen e Ibrahimit. Ti je i Lavdëruar, i Madhërishëm. O Allah, jepi begati Muhamedit dhe familjes së Muhamedit, ashtu siç i dhe begati familjes së Ibrahimit. Ti je i Lavdëruar, i Madhërishëm.'),
    'after_adhan': ('Pas ezanit', 'O Allah, Zot i kësaj thirrjeje të plotë dhe i namazit që do të falet, jepi Muhamedit Vesilen dhe pozitën e lartë, dhe ngrije në vendin e lavdëruar që ia ke premtuar.'),
    'entering': ('Hyrja në xhami', 'O Allah, m’i hap dyert e mëshirës Tënde.'),
    'leaving': ('Dalja nga xhamia', 'O Allah, të kërkoj nga mirësia Jote.'),
    'after_wudu': ('Pas abdesit', 'Dëshmoj se vetëm Allahu meriton të adhurohet, pa asnjë ortak, dhe se Muhamedi është robi dhe i Dërguari i Tij.'),
    'going': ('Rrugës për në xhami', 'O Allah, vendos dritë në zemrën time, dritë në gjuhën time, dritë në dëgjimin tim, dritë në shikimin tim, dritë sipër meje, dritë poshtë meje, dritë djathtas meje, dritë majtas meje, dritë përpara meje, dritë prapa meje dhe më jep dritë.'),
}

# Keys identify the existing English wording, so a changed base sentence requires
# an explicit translation update rather than silently retaining stale prose.
VIRTUES = {
    'morning_ayat_kursi': 'Kush e lexon në mëngjes mbrohet nga xhinët deri në mbrëmje.',
    'morning_ikhlas': 'Kush i lexon tri herë në mëngjes dhe në mbrëmje, ato do t’i mjaftojnë kundër çdo gjëje.',
    'morning_radeetu': 'Allahu e ka marrë përsipër ta kënaqë atë që e thotë tri herë në mëngjes dhe në mbrëmje.',
    'morning_bismillah_la_yadurr': 'Atë që e thotë tri herë nuk do ta godasë papritur ndonjë fatkeqësi.',
    'morning_subhanallah_adada': 'Këto fjalë peshojnë më shumë se gjithë dhikri i thënë që nga mëngjesi.',
    'morning_ushhiduka': 'Kush e thotë katër herë në mëngjes ose në mbrëmje, Allahu e liron nga Zjarri.',
    'morning_hasbiyallah': 'Kush e thotë shtatë herë në mëngjes dhe në mbrëmje, Allahu i mjafton për të gjitha shqetësimet e tij.',
    'morning_ma_asbaha_nimah': 'Kush e thotë, e ka përmbushur falënderimin që i takon asaj dite.',
    'morning_salah_nabi': 'Kush dërgon salavate mbi Profetin ﷺ dhjetë herë në mëngjes dhe dhjetë në mbrëmje, do të fitojë ndërmjetësimin e tij Ditën e Ringjalljes.',
    'morning_sayyidul_istighfar': 'Kush e thotë ditën me bindje dhe vdes atë ditë, do të jetë prej banorëve të Xhenetit.',
    'morning_tahlil_100': 'Kush e thotë njëqind herë në ditë, merr shpërblimin e lirimit të dhjetë robërve, i shkruhen njëqind vepra të mira, i fshihen njëqind gjynahe dhe mbrohet nga shejtani atë ditë.',
    'morning_subhanallah_bihamdihi': 'Kush e thotë 100 herë në ditë, i falen gjynahet edhe nëse janë sa shkuma e detit.',
    'evening_ayat_kursi': 'Kush e lexon në mbrëmje mbrohet nga xhinët deri në mëngjes.',
    'evening_audhu_kalimat': 'Atij që e thotë tri herë në mbrëmje nuk do t’i ndodhë asnjë dëm atë natë.',
    'evening_sayyidul_istighfar': 'Kush e thotë natën me bindje dhe vdes atë natë, do të jetë prej banorëve të Xhenetit.',
    'evening_subhanallah_bihamdihi': 'Kush e thotë 100 herë, i falen gjynahet edhe nëse janë sa shkuma e detit.',
    'salah_allahu_akbar': 'Plotësimi i njëqind përsëritjeve me tehlilin shlyen gjynahet, edhe nëse janë sa shkuma e detit.',
    'salah_ayat_kursi': 'Atë që e lexon pas çdo namazi të detyrueshëm, vetëm vdekja e ndan nga hyrja në Xhenet.',
    'salah_ilman_nafian': 'Profeti ﷺ e thoshte pas selamit të namazit të sabahut.',
    'sleep_ayat_kursi': 'Kush e lexon kur shkon në shtrat, ka një ruajtës nga Allahu dhe asnjë shejtan nuk i afrohet deri në mëngjes.',
    'sleep_tasbih_fatima': 'Profeti ﷺ ia mësoi këtë Fatimes në vend të një shërbëtori; për të ishte më mirë se një shërbëtor.',
    'sleep_ikhlas': 'Profeti ﷺ e bënte këtë çdo natë para gjumit.',
    'sleep_night_fear': 'Lexohet për një fëmijë ose për veten kur trembesh ose frikësohesh natën.',
    'sleep_aslamtu': 'Kush e thotë dhe vdes atë natë, vdes në natyrshmërinë e pastër të besimit (fitre).',
    'daily_after_eating': 'Kush e thotë pas ushqimit, i falen gjynahet e kaluara.',
    'daily_leaving_home': 'Atij i thuhet: Je i udhëzuar, i mbrojtur dhe i ruajtur; shejtani largohet prej tij.',
    'daily_wearing_clothes': 'Kush e thotë kur vesh një rrobë, i falen gjynahet e kaluara.',
    'daily_marketplace': 'Kush e thotë në treg, Allahu i shkruan një milion vepra të mira, i fshin një milion vepra të këqija dhe i ndërton një shtëpi në Xhenet.',
    'daily_anger': 'Profeti ﷺ ka thënë se zemërimi vjen nga shejtani. Ai që zemërohet të ulet nëse është në këmbë, ose të shtrihet nëse është ulur.',
    'daily_jazakallah_khayr': 'Atij që i thuhet kjo, i është bërë falënderimi më i plotë.',
    'daily_seeing_afflicted': 'Thuhet me zë të ulët, pa e dëgjuar personi i sprovuar. Kush e thotë nuk do të goditet nga ajo sprovë.',
    'forgiveness_astaghfirullah_azim': 'Kush e thotë, falet edhe nëse ka ikur nga fusha e betejës.',
    'forgiveness_yunus': 'Nuk ka musliman që lutet me këtë për diçka dhe Allahu të mos i përgjigjet.',
    'forgiveness_rabbana_zalamna': 'Lutja e Ademit dhe Havasë pas gabimit të tyre.',
    'distress_hasbunallah': 'Fjalët e Ibrahimit kur u hodh në zjarr, si dhe të Profetit ﷺ dhe të besimtarëve.',
    'distress_musibah': 'Kush e thotë kur e godet një fatkeqësi, Allahu e shpërblen për të dhe ia zëvendëson humbjen me diçka më të mirë.',
    'distress_against_oppressor': 'Profeti ﷺ e thoshte përballë një armiku nga i cili kishte frikë.',
    'travel_stopping': 'Kush e thotë kur ndalon në një vend, asgjë nuk e dëmton deri sa të largohet prej tij.',
    'travel_astawdiuka': 'Profeti ﷺ ia thoshte atij që nisej për udhëtim.',
    'mosque_adhan_testimony': 'Thuhet kur dëgjohet muezini. Profeti ﷺ i ka premtuar faljen e gjynaheve atij që e thotë.',
    'mosque_adhan_response_hayya': 'Thuhet në vend të përsëritjes së muezinit te «Hajje ales-salah» dhe «Hajje alel-felah». Pjesa tjetër e ezanit përsëritet fjalë për fjalë.',
    'mosque_after_adhan_salawat': 'Pasi t’i përgjigjesh muezinit, dërgo salavate mbi Profetin ﷺ para se t’i kërkosh Allahut Vesilen për të. Për një salavat Allahu jep dhjetë bekime. Kjo është një formë e vërtetuar; hadithi i ezanit nuk e kërkon posaçërisht këtë formulë.',
    'mosque_after_adhan': 'Kush e thotë pas ezanit, do ta meritojë ndërmjetësimin tim Ditën e Ringjalljes.',
    'mosque_after_wudu': 'Atij që e kryen mirë abdesin dhe e thotë këtë, i hapen të tetë dyert e Xhenetit dhe mund të hyjë nga cilado prej tyre.',
    'mosque_going': 'Pjesë e lutjes së Profetit ﷺ kur dilte për në xhami natën.',
}

INSTRUCTIONS = {
    'salah_tasbih_tahlil_final': 'Pas 33 herë Subhanallah, 33 herë Elhamdulilah dhe 33 herë Allahu ekber, thuaje këtë një herë për të plotësuar njëqind përsëritje.',
    'sleep_ikhlas': 'Para gjumit, bashkoji duart, fryj lehtë në pëllëmbë dhe lexo suret El-Ihlas, El-Felek dhe En-Nas. Fërko me duar sa më shumë nga trupi, duke filluar nga koka, fytyra dhe pjesa e përparme e trupit. Përsërite të gjithë rendin e fryrjes, leximit dhe fërkimit tri herë.',
    'waking_alhamdulillah_ahyana': 'Kur zgjohesh, largoji me dorë gjurmët e gjumit nga fytyra, siç bënte Profeti (Sahihu i Buhariut 183). Ky është veprim, jo fjalë për t’u lexuar.',
    'waking_imran_190_200': 'Kur zgjohesh gjatë natës, lexo këto ajete përmbyllëse të sures Ali Imran (3:190–200).',
    'daily_entering_home': 'Përmende Allahun kur hyn dhe përshëndeti familjarët me selam. Këto praktika vërtetohen më vete në Muslim 2018 dhe Kuran 24:61. Vlerësimi i kësaj lutjeje të transmetuar është i diskutueshëm: Ibn Bazi e vlerësoi hasen, ndërsa Albani të dobët.',
    'daily_wearing_clothes': 'Kjo lutje thuhet kur vesh një rrobë, qoftë të re apo të përdorur. Kur vesh këpucët, fillo me këmbën e djathtë; kur i heq, fillo me të majtën. Udhëzimi për këpucët është veprim, jo fjalë për t’u lexuar.',
    'daily_wearing_new_clothes': 'Kur vesh këpucët, fillo me këmbën e djathtë; kur i heq, fillo me të majtën (Sahihu i Muslimit 2097).',
    'travel_returning': 'Në kthim, thuaj të njëjtën lutje si në nisje dhe shto në fund: Ajibune, taibune, abidune, li-Rabbina hamidun.',
    'mosque_adhan_testimony': 'Thuhet pasi muezini përfundon dy dëshmitë e besimit, para se të thotë «Hajje ales-salah».',
}


def quran(surah, ayah):
    path = ROOT / f'assets/data/quran/trans/sq/surah_{surah}.json'
    return json.loads(path.read_text(encoding='utf-8'))['ayahs'][ayah - 1]


def excerpt(surah, ayah, start):
    text = quran(surah, ayah)
    suffix = text[text.index(start):]
    # Restore surrounding presentation punctuation without changing the exact
    # published excerpt. Some excerpts drop the source's opening context.
    if '”' in suffix and '“' not in suffix:
        return '“' + suffix
    return suffix


def published(title, meaning):
    """Mark Quran wording so its translator also travels on dua cards/shares."""
    return title, meaning, True


def rendering(dua):
    dua_id = dua['id']
    prefix, suffix = dua_id.split('_', 1)
    if suffix == 'ayat_kursi':
        title = 'Ajeti i Kursiut para gjumit' if prefix == 'sleep' else 'Ajeti i Kursiut'
        return published(title, quran(2, 255))
    if suffix in ('ikhlas', 'falaq', 'nas'):
        number, name, count = {
            'ikhlas': (112, 'Surja El-Ihlas', 4),
            'falaq': (113, 'Surja El-Felek', 5),
            'nas': (114, 'Surja En-Nas', 6),
        }[suffix]
        return published(name, quran(1, 1) + '\n\n' + '\n'.join(quran(number, n) for n in range(1, count + 1)))
    if suffix == 'hasbiyallah':
        return published('Allahu më mjafton', excerpt(9, 129, 'Më mjafton mua Perëndia'))
    if dua_id == 'waking_imran_190_200':
        return published('Ajetet e fundit të sures Ali Imran (3:190–200)', '\n\n'.join(f'({n}) {quran(3, n)}' for n in range(190, 201)))
    fragments = {
        'forgiveness_yunus': ('Lutja e Junusit', 21, 87, 'S’ka zot tjetër përveç Teje!'),
        'forgiveness_rabbana_zalamna': ('Lutja e Ademit', 7, 23, 'O Zoti ynë!'),
        'forgiveness_rabbana_la_tuakhidhna': ('Falja për harresën dhe gabimin', 2, 286, 'Zoti ynë, mos na ndëshko'),
        'forgiveness_rabbanaghfirlana': ('O Zoti ynë, ne kemi besuar', 3, 16, 'Zoti ynë!'),
        'distress_hasbunallah': ('Allahu na mjafton', 3, 173, 'Neve na mjafton Perëndia'),
    }
    if dua_id in fragments:
        title, surah, ayah, start = fragments[dua_id]
        return published(title, excerpt(surah, ayah, start))
    if dua_id == 'distress_musibah':
        return published('Në fatkeqësi ose humbje', excerpt(2, 156, 'Të Zotit jemi') + ' O Allah, më shpërble për fatkeqësinë time dhe ma zëvendëso atë me diçka më të mirë.')
    if dua_id == 'travel_setting_off':
        return published('Nisja për udhëtim', 'Allahu është më i Madhi (tri herë). “' + excerpt(43, 13, 'Qoftë lavdëruar Ai') + ' ' + quran(43, 14) + ' O Allah, në këtë udhëtim të kërkojmë mirësi, devotshmëri dhe vepra që të kënaqin Ty. O Allah, na e lehtëso këtë udhëtim dhe na e shkurto largësinë e tij. O Allah, Ti je shoqëruesi ynë në udhëtim dhe kujdestari i familjes sonë. O Allah, kërkoj mbrojtjen Tënde nga vështirësitë e udhëtimit, nga pamjet pikëlluese dhe nga kthimi i keq në pasuri dhe në familje.')
    if dua_id == 'travel_returning':
        return published('Kthimi nga udhëtimi', rendering({'id': 'travel_setting_off'})[1] + ' Kthehemi të penduar, duke adhuruar dhe duke lavdëruar Zotin tonë.')
    title, meaning = FORMULAS[suffix]
    time = 'mëngjes' if prefix == 'morning' else 'mbrëmje'
    if suffix == 'ushhiduka':
        meaning = f'O Allah, e arrita këtë {time} duke të marrë Ty për dëshmitar, si dhe bartësit e Fronit Tënd, engjëjt e Tu dhe të gjitha krijesat e Tua, se Ti je Allahu. Nuk ka të adhuruar me të drejtë përveç Teje, të Vetëm e pa ortak, dhe se Muhamedi është robi dhe i Dërguari Yt.'
    elif suffix == 'fitrah':
        meaning = f'E arritëm këtë {time} në natyrshmërinë e Islamit, në fjalën e përkushtimit të sinqertë (dëshminë e besimit), në fenë e Profetit tonë Muhamed ﷺ dhe në besimin e atit tonë Ibrahim, i cili ishte i drejtë, musliman dhe nuk ishte prej atyre që i bëjnë ortak Allahut.'
    elif suffix in ('ma_asbaha_nimah', 'ma_amsa_nimah'):
        meaning = f'O Allah, çdo mirësi që më ka ardhur mua ose ndonjë krijese Tënde këtë {time}, vjen vetëm prej Teje, pa asnjë ortak. Prandaj Ty të takon i gjithë lavdërimi dhe i gjithë falënderimi.'
    return title, meaning, False


def reference(text):
    replacements = dict((
        ('Sahih al-Bukhari', 'Sahihu i Buhariut'),
        ('Sahih Muslim', 'Sahihu i Muslimit'),
        ('Sunan Abi Dawud', 'Suneni i Ebu Davudit'),
        ('Sunan at-Tirmidhi', 'Suneni i Tirmidhiut'),
        ('Sunan Ibn Majah', 'Suneni i Ibn Maxhes'),
        ('Musnad Ahmad', 'Musnedi i Ahmedit'),
        ('Qur\'an', 'Kurani'),
        ('Tirmidhi', 'Tirmidhiu'), ('Muslim', 'Muslimi'),
        ('At-Tabarani', 'Taberaniu'), ('An-Nasa\'i', 'Nesaiu'),
        ('an-Nasa\'i', 'Nesaiu'), ('Ibn Majah', 'Ibn Maxhe'),
        ('graded hasan', 'vlerësuar hasen'),
        ('graded sahih by', 'vlerësuar sahih nga'),
        ('recited after each prayer', 'lexohet pas çdo namazi'),
    ))
    # Replace each original span once; a replacement must not subsequently be
    # re-translated (e.g. Muslim -> Muslimi inside the translated Muslimit).
    pattern = re.compile('|'.join(re.escape(key) for key in sorted(replacements, key=len, reverse=True)))
    return pattern.sub(lambda match: replacements[match.group(0)], text)


def generate(duas=None):
    if duas is None:
        duas = json.loads((ROOT / 'assets/data/duas.json').read_text(encoding='utf-8'))
    fingerprint = hashlib.sha256(json.dumps(duas, ensure_ascii=False, sort_keys=True).encode('utf-8')).hexdigest()
    if fingerprint != EXPECTED_BASE_SHA256:
        raise ValueError('Base dua content changed. Review and update the Albanian translations before updating EXPECTED_BASE_SHA256. Current source: ' + fingerprint)
    by_id = {dua['id']: dua for dua in duas}
    virtues = {by_id[dua_id]['virtue']: value for dua_id, value in VIRTUES.items()}
    instructions = {by_id[dua_id]['instruction']: value for dua_id, value in INSTRUCTIONS.items()}
    output = {'_meta': {
        'status': 'DRAFT — original project Albanian hadith renderings require qualified Albanian and religious review before release',
        'scope': 'Albanian titles, meanings, references, virtues and practical instructions; original Arabic recitations are unchanged.',
        'authorship': 'Hadith prose is original project translation of the existing bundled Arabic/English content, not a published Albanian translator transcription.',
        'baseContentSha256': fingerprint,
        'quran': {
            'translator': 'Hasan Efendi Nahi', 'edition': 'sq.nahi',
            'source': 'https://tanzil.net/trans/sq.nahi',
            'terms': 'https://tanzil.net/trans/',
            'method': 'Verbatim complete verses/surahs and exact suffix excerpts from bundled sq/surah_N.json. Mixed Quran/hadith texts preserve those exact Quran excerpts.',
        },
        'referencePolicy': 'Reference identifiers and reported grading notes follow the bundled base content; this work does not independently authenticate narrations.',
    }}
    for dua in duas:
        title, meaning, contains_quran = rendering(dua)
        entry = {'title': title, 'translation': meaning, 'reference': reference(dua['reference'])}
        if contains_quran:
            entry['reference'] += ' · ' + QURAN_CREDIT
        if dua.get('virtue'):
            entry['virtue'] = virtues[dua['virtue']]
        if dua.get('instruction'):
            entry['instruction'] = instructions[dua['instruction']]
        if any(not isinstance(value, str) or not value.strip() for value in entry.values()):
            raise ValueError(f"Missing Albanian field: {dua['id']}")
        output[dua['id']] = entry
    return output


if __name__ == '__main__':
    path = ROOT / 'assets/data/duas.sq.json'
    path.write_text(json.dumps(generate(), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Generated assets/data/duas.sq.json')
