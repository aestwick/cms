-- Migration 013: Seed shows from Aiir scrape
-- Imports 99 shows from the scraped Aiir show pages into cms_shows
-- Links are cleaned: Aiir share-button URLs are filtered out,
-- archive links stored separately, platforms auto-detected.

-- Use the KPFK station row; create a variable for clarity
DO $$
DECLARE
  kpfk_station_id uuid;
BEGIN
  SELECT id INTO kpfk_station_id FROM cms_stations WHERE slug = 'kpfk';
  IF kpfk_station_id IS NULL THEN
    RAISE EXCEPTION 'KPFK station not found. Run foundation seed first.';
  END IF;

  INSERT INTO cms_shows (station_id, title, slug, description, social_links, contact_email, website_url, is_active)
  VALUES
    (kpfk_station_id, 'Afro Dicia', 'afrodicia1', 'Afrodicia Saturdays 4pm-6pm pst Host: Nnamdi Moweta Email: afrodicia2011@gmail.com Facebook: Radio Afrodicia Twitter: Radio Afrodicia YouTube: Radio Afrodicia- Enjoy past interviews with some of our studio guests via our YouTube page. Website: Afrodicia.com - To keep up with the concerts and shows that are happening in and around Los Angeles, visit the Local Events page of our website. Listen live to Afrodicia, Saturdays from 4-6pm, Join Nnamdi Moweta playing all the best in modern and classic African music.

Description: Radio Afrodicia, hosted by Nnamdi Moweta, is a weekly experience into the world of African music from all across the Diaspora. With classic and modern tracks ranging from AfroBeat to Zouk, Radio Afrodicia hits the mark and wets your appetite for African and Afro-Caribbean music.

Archives:

Current Playlist

Previous Playlists: (select date)

http://www.facebook.com/afrodicia.baba', '{"facebook": "http://www.facebook.com/afrodicia.baba"}'::jsonb, 'afrodicia2011@gmail.com', 'http://www.afrodicia.com/', true),
    (kpfk_station_id, 'Alan Watts', 'alan-watts2', 'The three main sources for Alan Watts tapes and information:

Pacifica Radio Archives, 1 (800) 735-0230, www.pacificaradioarchives.org ;

and Electronic University,415-460-0825, www.alanwatts.org

ARCHIVES:

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{"archive": "http://www.pacificaradioarchives.org/"}'::jsonb, NULL, 'http://www.alanwatts.org/', true),
    (kpfk_station_id, 'All Of The Above', 'all-of-the-above', 'http://www.aotaradio.com/index.php/about-us/

Transmitting live from the West Coast of the Milky Way, our weekly radio show explores high quality music of every genre.  With no commercials and no playlist, All Of The Above is a non-stop journey through sound unlike any other found on today’s airwaves.  Host Django Craig and DJ Ben Vera teamed up with the specific vision of achieving something ground breaking and sky shattering.  What resulted was not only genre bending but also lively and infectious.  Using rare vinyl, hypnotic drums and eclectic grooves we take you on a journey into sound and what is possible when all limits are removed.  All recordings are 100% live and in free form with nothing premeditated.  Anything  and everything can happen!

Django Craig is a lyricist and music composer from Altadena, CA, USA.  He has previously released numerous spacey underground funk/ hip-hop albums that garnered a cult following in Southern California over the last 10 years.  This talented vocalist and multi-instrumentalist has performed with the likes of the Grammy Award winning group Ozomatli and musical legend George Clinton (Parliament/ Funkadelic).  His unorthodox approach to rhythm and synthesis add a natural organic feel to the sonic landscape that challenges the senses and moves the soul.  An avid crate digger and student of the funk, Django is our cosmic tour guide to infinity and beyond.  “AOTA is about tuning into a higher frequency and opening up parts of the mind and soul that need nourishment.  Our mission is to take you up, up and away.  We’re gonna blow the cobwebs out your mind….”

Ben Vera is an experienced DJ from Pasadena, CA, USA specializing in video DJing and music production.  His skills have graced stages and clubs in over 30 countries as well as radio airwaves in multiple countries.  Ben has also been on the cusp of future technologies working with experimental video programs, stereo 3D  and video DJ systems on major tours.  His skills have been utilized on some of the largest stages in the world by artists like Steve Aoki & members of the Grammy Award Winning group Black Eyed Peas.  Still fascinated with recording engineering and sound design Ben is constantly crafting unique sounds.  “My favorite thing to do while mixing during this show is to try and play the most unpredictable and unheard of monster jams that you would never hear anywhere else.  A DJ set perfect for sampling, dancing or freestyle rapping”.

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{}'::jsonb, NULL, 'http://www.aotaradio.com/index.php/about-us/', true),
    (kpfk_station_id, 'Alternative Radio', 'alternative-radio', 'Alternative Radio , established in 1986, is an award-winning weekly one-hour public affairs program. AR provides information, analyses, and views that are frequently ignored or distorted in corporate media. Guests analyze national and international issues. Airing Wednesdays at 2:00 PM. https://www.alternativeradio.org/ info@alternativeradio.org (303) 473-0972 (local) (800) 444-1977 (toll-free) P.O. Box 551 Boulder, CO 80306', '{}'::jsonb, 'info@alternativeradio.org', 'https://www.alternativeradio.org/', true),
    (kpfk_station_id, 'American Indian Airwaves', 'american-indian-airwaves', 'HOSTS : Marcus V. Lopez, and Larry Smith EMAIL :  Larry Smith: burnt.swamp@verizon.net

FACEBOOK: https://www.facebook.com/AIACR WEBSITE: http://www.myspace.com/aiairwaves DESCRIPTION: American Indian Airwaves is produced in Coyote Radio and Burntswamp Studios and was established in 1988 in order to give indigenous peoples and their respective first nations a voice about the continuous struggles against Colonialism and Imperialism by the occupying and settler societies often referred to as the United States, Canada, Mexico, and Latin and South America countries located therein. American Indian Airwaves Bios: Marcus V. Lopez (Chumash Nation) is the Producer and Co-host of Coyote Radio?s: American Indian Airwaves and has been a community organizer for over 20 years. Larry Smith (Lumbee Nation) is a part-time lecturer at California State University, Long Beach and teaches for the Film Electronic and Arts and American Indian Studies Departments. He is also a member of Tiat Society  and the Mt. Adams Lake Singers located in Long Beach, CA. He is also a community activist and can be reached at burnt.swamp@verizon.net

(Former Host) Corey S. Dubin Executive Producer: Coyote Radio. Corey Dubin has been a journalist for 26 years. In the early 1980s He free-lanced covering Latin America and the Pacific Rim. In the mid 1980s he was News & Public Affairs Director for KPFK, Pacifica Radio in Los Angeles. He then, in 1987 joined the Other Americas Radio as a senior documentary producer. Along with Eric Swartz TOA produced a wide range of cutting edge programs on Latin America, Iran-Contra and related issues. He also produced specials for Pacifica''s Iran-Contra coverage. In 1989 Dubin founded Coyote Radio and has been producing programming throughout the 1990s and into the current period. In 1992 Coyote Radio and American Indian Airwaves joined forces and produced a twenty hour special for KPFK entitled ?Break The Blackout: 500 Years of Resistance? He also remains the President of the Committee of Ten Thousand a national HIV/AIDS advocacy and support organization headquartered in Washington D.C.

ARCHIVES', '{"facebook": "https://www.facebook.com/AIACR"}'::jsonb, 'burnt.swamp@verizon.net', NULL, true),
    (kpfk_station_id, 'Arts in Review', 'arts-in-review', 'EMAIL: julima@aol.com

DESCRIPTION: Arts in Review celebrates the best in local live performance, including theatre, cabaret, music and dance. Hosted by arts journalist Julio Martinez, the weekly one-hour program features interviews and performances by a wide range of talented performers who are performing locally.

Listen to archives of this show [ here ]', '{"archive": "https://archive.kpfk.org/index.php?shokey=artsinreview"}'::jsonb, 'julima@aol.com', NULL, true),
    (kpfk_station_id, 'Awakenings', 'awakenings', 'Awakenings A journey into the music and spiritual legacy of John and Alice Coltrane SATURDAYS • 4:00 AM • KPFK 90.7 FM Hosted by Michelle Coltrane 🎧 Listen & Archive

Overview Awakenings with Michelle Coltrane invites listeners on a meditative journey into the music and spiritual legacy of John and Alice Coltrane. Each week, the show blends celestial jazz, transcendent compositions, and the soulful improvisations that defined a generation. Through stories and sounds, Michelle explores the Coltranes'' vision of liberation through music and the cosmic connections that continue to inspire artists today. Early morning audiences are guided into a reflective, soulful start to their day. Awakenings isn''t just a music show — it''s a spiritual soundtrack for awakening the mind and spirit. Spiritual Jazz Legacy Artists Cosmic Music Music Performance & Archives Artist Stories Guided Listening Jazz Enthusiasts Spiritual Seekers

History & Legacy Awakenings honors the rich and transformative legacy of the Coltrane family, whose music continues to inspire spiritual seekers and artists around the world. John Coltrane''s quest for liberation through sound and Alice Coltrane''s deeply spiritual compositions have shaped generations of listeners. Michelle Coltrane carries this lineage forward, creating a bridge between past and present through her own artistic voice. The show connects the timeless messages of love, freedom, and transcendence to today''s audience, reminding us of music''s power to heal and unite. Awakenings stands as a living tribute to a family whose sonic vision reshaped the possibilities of jazz and spiritual music.

Host Michelle Coltrane Michelle Coltrane is a vocalist, composer, and cultural ambassador deeply rooted in her family''s legendary musical legacy. As the daughter of John and Alice Coltrane, she carries forward their spirit of exploration, transcendence, and healing through sound. Michelle creates an inviting space for listeners to experience music as a pathway to higher consciousness and community connection. ✉️ Contact Host

awakenings

Recent Episodes KPFK Player v2

Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Donate Now

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{"instagram": "https://instagram.com/michellecoltrane"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Aware with Lisa Garr', 'aware-show', 'Wednesdays, 1-2 PM

HOST: Lisa Garr

EMAIL: gina@theawareshow.com

OFFICIAL WEBSITE: www.theawareshow.com THE AWARE SHOW on Facebook:

Embed not found

DESCRIPTION: Aware is dedicated to communicating information to inspire positive growth and change. Our goal is an increased awareness and healing on an individual and planetary level. Based on our commitment to the renewal of the human spirit, and combined with our pure faith in the power of love, we are answering a call to action for a more conscious world.

The Aware show archives are available at: www.theawareshow.com

Podcasts can also be found here -', '{}'::jsonb, 'gina@theawareshow.com', 'http://www.theawareshow.com/', true),
    (kpfk_station_id, 'Be a Better Relative', 'be-a-better-relative', 'Lydia Ponce and Sunny Rose Iron Shell cover Indigenous land and water protectors, environmentalism, and issues surrounding Missing and Murdered Indigenous Women, Indigenous traditions, and sovereignty, in a weekly program with conversations and guests. Tuesdays at 7:30 PM.', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Beautiful Struggle', 'beautiful-struggle', 'Beautiful Struggle Tuesdays  7pm - 8pm Beautiful Struggle Collective : Kimberly King, Kelly Madison, Michael Datcher, Penni Wilson, Audrena Redmond, and Melina Abdullah Listen to archives of this show [ here ] Beautiful Struggle is an open conversation focused on African American social and political issues, thought, history, inspiration, resistance, and social change. The program aims to educate and motivate the audience to work for justice and social change. It consists of illuminating interviews with scholars, activists, youth, artists, and numerous other community voices. We will bring you people not likely to be seen or heard in corporate media, views and analyses not typically allowed or explored.  Interviews will be followed by 15-20 minutes of dialogue with the listener audience. Acknowledging the role of music and art in the beautiful struggle, each show will close with a live hip-hop, spoken word, or other performance from conscious underground performers. Beautiful struggle will be of interest to progressives of all backgrounds interested in African Americans'' Beautiful Struggle for equality and social justice! Twitter Feed: Tweets by bestruggle', '{"archive": "http://archive.kpfk.org/index.php?shokey=beautifulstruggle", "twitter": "https://twitter.com/bestruggle?ref_src=twsrc%5Etfw"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Beneath the Surface with Suzi Weissman', 'beneath-the-surface', 'Beneath the Surface with Suzi Weissman In-depth conversations on politics, economics, and movements — cutting past headlines to what really matters. Sundays • 10:00 AM • KPFK 90.7 FM Host: Suzi Weissman | Executive Producer: Robert Brenner | Producer: Alan Minsky ▶ Episodes About the Show Beneath the Surface with Suzi Weissman has been on KPFK since 1994, bringing listeners into conversation with the ideas and struggles shaping our world. Each week, Suzi talks with leading thinkers and activists about politics, economics, labor, and social movements — always digging deeper than the headlines. Suzi Weissman began broadcasting on KPFK in 1981 with Portraits of the USSR and Read All About It . After the Soviet collapse, she created The New World Disorder (1993–1995). Since 1994 she has hosted Beneath the Surface , with early archives preserved at Stanford University''s Hoover Institution. Topics on the program range from the breakup of the USSR and shifting politics in Eastern Europe, to global financial crises and their aftermath, labor struggles and working-class politics, the history of socialism and experiments in social change, and mass uprisings from the Arab Spring and Occupy to Syriza, Podemos, and the rise of right-wing populism. Host & Team Suzi Weissman Host and creator of Beneath the Surface , Suzi is a journalist, scholar, and award-winning broadcaster. She edits Against the Current and Critique , and is the author of Victor Serge: The Course is Set on Hope . Her interviews bring clarity and urgency to global political debates. Robert Brenner Executive Producer. Director of UCLA''s Center for Social Theory and Comparative History and a leading historian of political economy. His books include The Boom and the Bubble , Merchants and Revolution , and The Economics of Global Turbulence . He also co-edited Rebel Rank and File and helps shape the program''s big-picture analysis. Alan Minsky Producer of Beneath the Surface and Executive Director of Progressive Democrats of America (PDA). Former Program Director at KPFK, he produced The Ralph Nader Radio Hour and the Nation Magazine podcast Start Making Sense . He is also a co-founder of the Los Angeles Independent Media Center. ✉ Contact bts_friday Episodes KPFK Episode Player Support Beneath the Surface & Independent Media Mainstream media won''t dig this deep. Beneath the Surface does, but only with your help. Support independent journalism and keep critical conversations alive on KPFK. Contribute', '{"facebook": "https://www.facebook.com/p/Beneath-the-Surface-with-Suzi-Weissman-100047612749507/"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Bibliocracy', 'bibliocracy', 'Website: http://bibliocracyradio.com/

Bibliocracy Radio is a weekly half-hour books discussion and interview program hosted by writer and Santa Monica Review editor Andrew Tonkovich featuring writers of literary fiction and nonfiction, poetry, memoir, political and cultural criticism.  Recent guests have included anti-fascist scholar Federico Finkelstein, So Cal novelist and editor David Ulin, writer Venita Blackburn, publisher and essayist Steve Wasserman, and short story writer Mary Jones. The show airs Thursdays at 2:30 PM as part of KPFK''s literary arts and culture strip of programming M-F at 2 PM.

For more on the show: https://www.bibliocracyradio. org/

Facebook:  Bibliocracy Radio.

The show is also available as a podcast.

Hungry man, reach for the book: It is a weapon." - Brecht

Theme music: "Black and White" by Earl Robinson and David Arkin Link: http://bibliocracyradio.blogspot.com

Listen to archives of this show [ here ]', '{"archive": "http://archive.kpfk.org/index.php?shokey=bibliocracy"}'::jsonb, NULL, 'http://bibliocracyradio.blogspot.com/', true),
    (kpfk_station_id, 'Bike Talk', 'bike-talk', 'Bike Talk Bikes first — people-powered transportation for all. Mondays • 4:00 AM • KPFK 90.7 FM Hosted by Nick Richert and Taylor Nichols ▶ Episodes About the Show Bike Talk is radio that puts people-powered transportation front and center. Every week, Nick Richert and Taylor Nichols open the mic to riders, grassroots leaders, mechanics, artists, policy shakers, and anyone building safer, more just streets—right here in LA and around the world. This show isn''t just for bike enthusiasts; it''s for everyone who believes our streets should serve people, not just cars. Bike Talk challenges mobility injustice, celebrates the everyday ride, and connects you to the movement for real transportation change. If you want a city that moves differently—more equitably, more sustainably—this is your show. Tune in Mondays at 4am and join the ride. History & Legacy Since 2008, Bike Talk has been a key platform for bicycle advocacy and transportation justice, amplifying the voices of riders, activists, mechanics, inventors, and community leaders from Los Angeles and beyond. The show has chronicled major milestones in the movement, from local policy campaigns and street safety initiatives to global efforts for sustainable transit. Through interviews with athletes, authors, filmmakers, politicians, and everyday cyclists, Bike Talk has bridged grassroots efforts with broader conversations about equity and mobility. Its legacy lies in connecting diverse advocates, spotlighting often-overlooked stories, and persistently challenging mobility injustice. For over a decade, Bike Talk has helped shape the public dialogue around people-powered transportation, inspiring listeners to envision streets that serve everyone. Hosts Nick Richert Nick Richert launched Bike Talk in 2008 to amplify LA''s rising bike movement and bring real conversations about streets, justice, and community to the airwaves. He''s been a steady voice for people-powered change, connecting with riders, mechanics, and everyday advocates who believe in a city that moves differently. Nick''s strength is finding the humanity and hope in every bike story—because for him, bikes aren''t just a topic; they''re a tool for building community. Taylor Nichols Taylor Nichols jumped into bike advocacy when his daughters started rolling through the neighborhood, sparking his mission for safer streets. Embedded in local organizing—from the Mid City West Neighborhood Council to the LA Bicycle Advisory Committee—Taylor brings the stories and struggles of everyday Angelenos fighting for mobility justice. He rides, listens, and pushes for roads that work for all, carrying both a parent''s heart and an activist''s drive into every show. ✉ Contact biketalka Episodes KPFK Episode Player Support Independent Media Support the voices shaping our streets. Your contribution keeps independent media alive at KPFK—and keeps Bike Talk pushing for safe, just roads for all. Join a community that powers real change. Donate today and help us keep bikes, stories, and ideas moving forward. Contribute', '{"facebook": "https://www.facebook.com/groups/livebiketalk/", "twitter": "https://twitter.com/biketalkpfk", "instagram": "https://www.instagram.com/biketalking", "archive": "https://archive.kpfk.org/xml/biketalk.xml"}'::jsonb, 'livebiketalk@gmail.com', 'https://biketalk.org', true),
    (kpfk_station_id, 'BradCast with Brad Friedman', 'bradcast-with-brad-friedman', 'DESCRIPTION: Investigative journalist, blogger, muckraker, troublemaker and broadcaster Brad Friedman''s investigative interviews, analysis and commentary, as ripped from the pages of The BRAD BLOG , today''s current events (if they matter) and even, on occasion, from the dark recesses of his mind. Live on the air and taking listener calls, Mondays at 3:00 PM, and podcasting Tue-Fri on the KPFK on-line archives.

Archives of The BradCast can be found right here . Subscribe to The BradCast''s podcast right here .

More on Brad Friedman right here .

ARCHIVES:

Tweets by TheBradBlog

Embed not found

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{"archive": "http://archive.kpfk.org/index.php?shokey=friedman"}'::jsonb, 'BradCast@BradBlog.com', 'http://BradBlog.com/Bio', true),
    (kpfk_station_id, 'Breakbeats and Rhymes', 'breakbeats-and-rhymes', 'Friday nights from 10 to 12 a.m . Hosted by Rebels to the Grain, bringing you the finest in Hip Hop music.

Weekly on-demand archive [ here ]

Breakbeats & Rhymes is your weekly dose of Hiphop goodness.  Fresh raps, classic cuts and exclusive interviews each Friday.

Hosted by MP, Stuckinthetrees & DJ Luman. Broadcasting live on KPFK since 2009. If you love the breaks, the beats, and the rhymes, tune in Friday at 10p.m. - Midnight

For media inquiries, song requests, song submission, etc. e-mail breakbeatsradio@gmail.com Instagram http://ww.instagram.com/breakbeatsandrhymes/ Twitter http://www.twitter.com/ReblsToTheGrain

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists', '{"archive": "http://archive.kpfk.org/index.php?shokey=bbeatsrhymes", "instagram": "http://www.instagram.com/breakbeatsandrhymes/", "twitter": "http://www.twitter.com/ReblsToTheGrain"}'::jsonb, 'breakbeatsradio@gmail.com', NULL, true),
    (kpfk_station_id, 'Cal State LA Community News Hour', 'cal-state-la-community-news-hour', 'Description : Local news and stories produced by the students and staff of the Cal State LA Broadcast and Journalism Department. Covering public issues that affect under-covered areas, such as South and East Los Angeles. First Sunday of the month at 10:00 AM.

Hosts/producers: April Brown, Julie Patel Liss, Braylin Collins, Alyssah Hall, Anne To, Xennia Hamilton & Arlyn Lopez.

Contact email: UTCommunityNews@gmail.com IG/Twitter: @UTCommunityNews

Guest reporters: Erik Adams, Marcos Franco, Alyssah Hall, Anh Tong, Priscilla Caballero, Citlalli Prado, Michelle Leon, Angelica Aguiniga, Erick Cabrera, Braylin Collins, Gerardo De Los Santos, Victoria Ivie, Imari Jackson, Michelle Leon, Vincent Moc, Eileen Osuna, Brian Perez, Citlalli Prado, Stephanie Sical, Meghan Bravo, Katherine Conchas, Ronald Cruz Orellana, Jericho Caleb Dancel, Marisa Escalante, Jorge Garcia, Juan Ricardo Gomez, Nicholas Juarez, Zoe Little, Marisa Martinez, Briana Munoz, Edward Nelson, Krysta Pae, Stephanie Presz, Brandon Rodriguez, Kilmer Salinas and Catherine Valdez.

Special thanks to others on the Cal State LA journalism team: Kristiina Hackel, Tony Cox, Albert Ramirez, JoAnne Lightford Powell, Shaunelle Curry, Nidhin Patel, Matthew Gatlin & Jesus Cruz

Sidelined: Bias in SoCal schools and youth sports? Southern Californians share experiences of discrimination in educational settings

Education is considered the great equalizer but what happens when students face inequality while trying to learn? Cal State LA’s Race, Class & Gender in American Journalism class created a podcast to explore stories of folks who grappled with racism, sexism, classism, nepotism and other forms of bias or discrimination in educational settings, including schools and athletic programs.

The 10 episodes produced cover a range of obstacles and biases. This project was produced by students in Cal State LA’s JOUR 3500 Race, Class & Gender in American Journalism class in collaboration with Golden Eagle Radio. GER Station Manager : Ronald Cruz Professor : Julie Patel Liss Developer : Vraj Mehalana Illustrators : Priscilla Caballero, Citlalli Prado and Michelle Leon Reporters : Angelica Aguiniga, Priscilla Caballero, Erick Cabrera, Braylin Collins, Gerardo De Los Santos, Victoria Ivie, Imari Jackson, Michelle Leon, Vincent Moc, Eileen Osuna, Brian Perez, Citlalli Prado & Stephanie Sical A special thanks to GER’s Carlos Estebes, Heidi Itzep-Poroj, Marianne Arambulo, and business manager Albert Ramirez.

Get more info and HEAR the stories HERE

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{}'::jsonb, NULL, 'http://goldeneagleradio.org/editors-pick/sidelined/', true),
    (kpfk_station_id, 'California Solartopia', 'california-solartopia', 'California Solartopia Relentless activism for a thriving planet. Wednesdays • 2:00 PM • KPFK.org Hosted by Harvey Wasserman, Myla Reson, & Tatanka Bricca ▶ Episodes About the Show California Solartopia is your frontline call to action in the fight for our planet''s future. Every week, hosts Harvey Wasserman, Myla Reson, and Tatanka Bricca break down California''s fiercest ecological battles — from the urgent push to shut down Diablo Canyon, to defending the Ballona Wetlands, stopping plastics, and exposing the dangers of nuclear energy and fracking. This is the show where local struggles meet global movements, and where people-powered activism takes center stage. If you''re ready to stand up for clean energy, urban forests, and a world free of toxic threats, California Solartopia is your rally point. No nukes—just relentless, nonviolent resistance for a thriving, just tomorrow. History & Legacy Harvey Wasserman, Myla Reson, and Tatanka Bricca have long stood at the heart of California''s environmental and anti-nuclear advocacy, bringing decades of activism and organizing to the airwaves. Their collective efforts have amplified frontline movements, especially around shutting down the Diablo Canyon nuclear plant and saving threatened ecosystems like the Ballona Wetlands. The anti-nuclear and clean energy work led by Wasserman in particular has spanned back to the 1970s, helping empower public resistance from California to national campaigns against nuclear power and fossil fuels. Through their broadcast work, the hosts have created a vital platform for environmental justice voices and nonviolent action, shaping public understanding and energizing local communities at critical moments in California''s ecological history. Hosts Harvey Wasserman Harvey Wasserman is a veteran journalist, activist, and organizer with deep roots in California''s anti-nuclear and grassroots clean energy movements. He''s been fighting for ecological justice and people-powered solutions for decades, bringing local stories and global urgency together on and off the airwaves. Harvey''s voice stands with communities demanding a just, sustainable future—no nukes, no compromise. Myla Reson Myla Reson is a longtime environmental advocate and on-the-ground organizer whose work bridges neighborhoods, natural spaces, and frontline movements across the Southwest. Whether working for Los Angeles to divest from Arizona''s Palo Verde nuclear power plant or campaigning to save the Ballona Wetlands, Myla connects with listeners as a neighbor in the fight for healthy, just communities. She inspires steady resistance and shares hope in every battle. Tatanka Bricca Tatanka Bricca is a lifelong nonviolent activist whose journey spans from Vietnam draft resistance and UFW boycott organizing to co-founding Amnesty International West Coast with Joan Baez. A Métis Medicine Wheel teacher, Sundancer, and jazz pianist, Tatanka has worked alongside leaders from Ben & Jerry to Mikhail Gorbachev. His decades in solar energy and deep roots in community radio embody the intersection of ecological action and cultural wisdom that powers California Solartopia. ✉ Contact solartopia Episodes KPFK Episode Player Support Independent Media KPFK runs on real people power. When you support California Solartopia, you''re fueling fearless, independent media that amplifies the voices and victories of frontline communities. Help us keep this platform rooted, radical, and fiercely free — your gift builds space for honest stories and a livable planet. Stand with us and invest in radio that won''t back down. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Caminando por Mesoamerica', 'caminando-por-mesoamerica', 'Vantana de denuncia y micrófonos solidarios con las luchas en mesoamerica', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Canto Sin Fronteras', 'canto-sin-fronteras', 'The best music from Latin- America and the World with a Political Edge Saturdays 6-8 p.m. Host: Tanya Mayahuel Torres Contact email: cantosinfronteraskpfk@yahoo.com Facebook: Canto Sin Fronteras https://www.facebook.com/canto.fronteras

Tanya Mayahuel Torres - Host, producer, director and board operator. Nelson Daza - Technical support Dana Lubow - Playlist Data Rudy Reyes - phone volunteer. Canto Sin Fronteras KPFK 90.7 FM sabados 6-8pm https://www.facebook.com/pg/Canto-Sin-Fronteras-KPFK-907-FM-sabados-6-8pm-782537835105584/about/?ref=page_internal

Canto sin Fronteras was created by Tanya Mayahuel Torres in 1995 in order to fulfill the great need for a radio forum where the progressive Latin-American and world audience could be represented in Southern California. The program is dedicated to the diffusion of Latin American folk, trova, nuevo canto, and World music with social-political themes not allowed on other radio stations. For the last 23 years Canto Sin Fronteras continues to be a unique program that provides a forum for world known song writers and singers that acknowledges the history, culture and currents social matters affecting Latin Americans and people from around the world living in the in the United States. Canto sin Fronteras has always emphasized history, culture and current social topics through music while outreaching the community through different cultural activities such as art expositions, concerts and forums. Through music Canto Sin Fronteras has united, empowered, and given voice to those that are often misrepresented in the world with the hope to achieve peace in the world through the understanding of diverse cultures. We are One!

Listen to archives of this show [ here ]

Canto Sin Fronteras Sabados :  6-8pm Presentadora: Tanya Mayahuel Torres Contacto: cantosinfronteraskpfk@yahoo.com Facebook: Canto Sin Fronteras https://www.facebook.com/canto.fronteras Canto Sin Fronteras KPFK 90.7 FM sabados 6-8pm https://www.facebook.com/pg/Canto-Sin-Fronteras-KPFK-907-FM-sabados-6-8pm-782537835105584/about/?ref=page_internal Canto sin Fronteras fue concebido por Tanya Mayahuel Torres en 1995 para llenar la gran necesidad de un foro radial en el cual la audiencia latinoamericana progresista pudiera ser representada. El programa está dedicado a la difusión del folklore latinoamericano, el nuevo canto, la trova, y la música del Mundo con contenido social no permitido en otras emisoras. Este programa se transmite todos los sábados de 6-8 PM en KPFK 90.7 FM en Los Ángeles, 98.7 FM Santa Bárbara, 93.7 FM San Diego, 99.5 FM Ridgecrest/China Lake y a través del mundo en www.kpfk.org

Canto Sin Fronteras además de ser un programa de radial, se ha preocupado en rescatar las raíces culturales de los pueblos de América latina y el mundo acentuando la historia, la cultura y los temas sociales actuales a través de la música, además de involucrar a su audiencia en otras actividades culturales tales como: exposiciones de arte, conciertos y foros comunitarios. Después de 23 anos en el aire Canto Sin Fronteras se ha convertido en un programa único y popular alrededor de la programación en español de Los Ángeles y del mundo por su carácter inclusivo y universal, además del gran apoyo que recibe de su audiencia.

Através de la música Canto Sin Fronteras ha unido, empoderado y dado voz a aquellos sin voz en el mundo, con su música ha expuesto a su audiencia a las diversas culturas del mundo para llegar a un mejor entendimiento y lograr la paz y la unidad universal. Inlakesh!, Mitakuye Oyasin!, Tehual Ne, Nehual Te!, Somos Uno Solo!.

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists', '{"facebook": "https://www.facebook.com/canto.fronteras", "archive": "http://archive.kpfk.org/index.php?shokey=cantossin"}'::jsonb, 'cantosinfronteraskpfk@yahoo.com', NULL, true),
    (kpfk_station_id, 'Canto Tropical', 'canto-tropical', 'Saturday, 8-10 p.m.

HOSTS: Kathy Diaz, Armando Nila and Hector Resendez

EMAIL: elcaballerosalsero@gmail.com , kanndiaz@yahoo.com and hectorlavoz@icloud.com

OFFICIAL WEBSITE: https://www.facebook.com/CantoTropical/

DESCRIPTION: “Canto Tropical” is a bilingual program that bridges cultures, generations and borders. It presents and promotes the world of Afro-Cuban music, salsa, and Latin jazz. The music featured on the show comes from around the world—the Caribbean, Central and South America, Europe and Africa. All rhythms and styles within the world of tropical music are presented. Exciting new selections are featured on the show along with insightful interviews with local and visiting artists. In addition, lucky listeners often win tickets to upcoming events.

In keeping with the mandate of KPFK, local artists and musicians are regular guests on the show. This provides them the often hard-to-find opportunity to promote their music, recordings and upcoming performances. Yet-to-be discovered artists and up-and-coming talent credit the show with giving their careers a timely boost.

TAPES / TRANSCRIPTS / PLAYLISTS: Playlists of the program are available at www.kpfk.org

Listen to archives of this show [ here ]

BIO AND OTHER INFO: Kathy “La Rumbera” Diaz, Armando “El Caballero Salsero” Nila, and Hector “La Voz” Resendez take great pride in bringing diversity to each of the weekend shows. The program has received accolades from numerous civic and community organizations for its volunteer endeavors. Kathy and Hector have written for Billboard Magazine, CASHBOX, Hispanic, AARP and various other publications. “Canto Tropical” hit the KPFK airwaves in 1986 and has been a highly acclaimed show ever since.

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists', '{"facebook": "https://www.facebook.com/CantoTropical/", "archive": "http://archive.kpfk.org/index.php?shokey=cantotropical"}'::jsonb, 'hectorlavoz@icloud.com', NULL, true),
    (kpfk_station_id, 'Capitalism, Race and Democracy', 'capitalism-race-and-democracy', 'Capitalism, Race & Democracy Pacifica''s national magazine show connecting labor, race, and democracy struggles across the U.S. and the world. Tuesdays • 7:00–7:30 AM • KPFK 90.7 FM Hosts: Various ▶ Episodes About the Show Capitalism, Race & Democracy (CRD) is produced by the Pacifica National Board and the CRD Collective. It features voices from all five Pacifica stations — WBAI in New York, WPFW in Washington DC, KPFT in Houston, KPFK in Los Angeles, and KPFA/KPFB in Berkeley — alongside Pacifica Affiliates and international reporters. Formerly COVID, Race & Democracy , the program rebranded as recurring themes became clear: labor exploitation, monopoly power, predatory pricing, imperialism, and corporate narrative control. CRD connects worker struggles, antiwar movements, and grassroots organizing to the larger fight for democracy and justice. covidraceanddemocr Episodes KPFK Episode Player Power Independent Voices Capitalism, Race & Democracy is made possible by listener support. Help us keep worker voices, grassroots movements, and independent reporting alive on the air. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Car Show, The', 'car-show-the', 'HOSTS: Mark Vaughn

EMAIL: Mark.Vaughn@hearst.com

DESCRIPTION: Everything about the automotive world including the latest technology, new and future vehicles, and the car culture of Southern California. The Car Show has aired continuously since 1973. Saturdays at 1:00 PM Listen to archives of this show [ here ]', '{"archive": "http://archive.kpfk.org/index.php?shokey=carshow"}'::jsonb, 'Mark.Vaughn@hearst.com', NULL, true),
    (kpfk_station_id, 'The Cary Harrison Files', 'the-cary-harrison-files', 'The Cary Harrison Files Where News Gets Undressed - and Truth Comes Out Wrinkled Fridays • 10:00 AM • KPFK 90.7 FM Hosted by Cary Harrison ▶ Episodes About the Show Welcome to The Cary Harrison Files — a fearless, satirical deep dive into the headlines, backroom deals, and unspoken absurdities shaping your world. Hosted by award-winning global correspondent and story sleuth Cary Harrison, this isn''t your grandmother''s news hour. Here, we pull apart the spin, laugh in the face of power, and expose the theater behind the politics, tech empires, and global chaos trying to pass as "normal." Each episode blends hard-hitting journalism, biting satire, and a flair for the unexpected — from dystopian deepfakes and institutional overreach to the unholy marriage between Big Tech and Big Brother. Expect probing interviews, sharp monologues, live call-ins, and unfiltered conversations with whistleblowers, authors, experts — even celebs who aren''t afraid to rattle the gates. Because in a world this upside-down, you don''t need another headline — you need a crowbar. Host & Team Cary Harrison Award-winning global correspondent and story sleuth, Cary blends fearless journalism with biting satire to host The Cary Harrison Files . His accolades include Vanderbilt University''s Siegenthaler Award for integrity and courage in journalism, the Sigma Delta Chi Award from the Society of Professional Journalists (two years running), honors from American Women in Radio & Television for investigative reporting, AP''s 1st place for Best Commentary, UN recognition for environmental and peace work, and an Edward R. Murrow Award nomination. Renèe Yaworski Director and Producer at Cosmos Creative TV, with legal training at Oxford and reporting experience with Impunity Watch. Renèe supports research and production for the show. ✉ Contact caryharrisfiles Episodes KPFK Episode Player Support Independent Media Your support keeps The Cary Harrison Files and KPFK fearless, unfiltered, and on the air. Help us undress the news and expose the spin—because independent media only survives with you. Contribute', '{"twitter": "https://x.com/caryharrison", "facebook": "https://facebook.com/caryharrison", "instagram": "https://instagram.com/caryharrison", "youtube": "https://www.youtube.com/@caryharrison"}'::jsonb, NULL, 'https://caryharrison.substack.com', true),
    (kpfk_station_id, 'Centroamerica Sin Censura con Francisco Marti­nez', 'centroamerica-sin-censura-con-francisco-marti­nez', 'BIENVENIDOS A  NUESTRA PAGINA ELECTRONICA EN NOMBRE DE TODOS AQUELLOS QUE HACEMOS POSIBLE CENTROAMERICA SIN CENSURA , QUEREMOS AGRADECERLES PROFUNDAMENTE POR ESTAR PENDIENTE DE NUESTRO PROGRAMA. !GRACIAS! Productor: Lic. FRANCISCO R. MARTINEZ fmartin6@yahoo.com CARTA A MAURICIO FUNES Querido Candidato:El 11 de Noviembre de 1989 es una fecha repiqueteante y con una solvente carga historica, por eso tÃº proclamaciÃ³n como candidato en esa fecha, vincula, amorosamente, una actividad electoral al mayor acontecimiento polÃ­tico del paÃ­s de las Ãºltimas dÃ©cadas.Resulta comprensible la expectaciÃ³n; pero vos sabÃ©s que resulta imprescindible que la expectativa se haga esperanza, la esperanza, es un fruto colectivo es como un mango indio hecho por todos, madurado por todos y comido, finalmente, por todos. Sin duda que se trata de regar la rosa fragante de la esperanza para que contamine, con su olor, a todos y todas incluso a los que ya no esperan nada.Tu discurso equilibrado resultÃ³ desequilibrante para todos aquellos y aquellas que han hecho de la patria un pastel de chocolate y necesitan del desequilibrio para que nadie mire las cucharas y los cuchillos con los que estos comensales madrugadores se hacen los bigotes con el pastel. En estas circunstancias se necesita del niÃ±o, el justo, sencillo y mÃ­nimo, que diga que el rey esta desnudo para que esta verdad, tambiÃ©n desnuda como suele andar la verdad que siempre es impÃºdica, rompa el desequilibrio y establezca uno nuevo desequilibrante. Se trata de eso, de un nuevo equilibrio de fuerzas que construya una correlaciÃ³n de poder, nueva y novedosa, para con esta palanca, poder construir un nuevo poder desequilibrante.Vos sabÃ©s candidato, muy bien lo sabes, que las palabras tienen olor y por eso tienen la funciÃ³n de domiciliar la sociedad adentro de nosotros y tÃº discurso resulta un texto que usa la palabra para romper con su contexto. Este entorno crÃ­tico nos muestra la confrontaciÃ³n entre una clase gobernante y una clase dominante, ambas son recientes y son vÃ­ctimas del Ã©xito de su polÃ­tica. El crecimiento de su economÃ­a niega una vida mejor para la mayorÃ­a y, siendo  asÃ­ las cosas desde siempre, resultan hoy mÃ¡s evidentes para las vÃ­ctimas y ofendidos, y por eso el clamor, de malestar y la protesta recorre como luz que enciende,  toda la patria.Me parece claro que un tema tan polÃ­tico como el de la economÃ­a haya sido abordado en el punto crucial de la relaciÃ³n entre el estado y el mercado y, siendo este ultimo un invento humano y no del capitalismo,  resulta imparajitable que debe ser regulado, precisamente por el estado; pero aquÃ­ tenemos la mayor confrontaciÃ³n con los neoliberales gobernantes y sin embargo esta posiciÃ³n adelantada nos podrÃ¡, como brÃºjula marina, seÃ±alar nuestro norte.La polÃ­tica exterior es, hoy mas que nunca, polÃ­tica interior y viceversa, todo lo relacionado al imperio estadounidense nos muestra su intervenciÃ³n en nuestra vida y tambiÃ©n, nuestra intervenciÃ³n en la vida de este ineludible cÃ­clope.Sin embargo, como vos sabes, la campaÃ±a electoral de la derecha tendrÃ¡, muy probablemente, a la revoluciÃ³n Venezolana y a Hugo ChÃ¡vez como un eje pivoteante, por eso tener, pensar y adoptar una posiciÃ³n clara y presentable sobre este tema es alcanzable y conveniente, y ademÃ¡s, inevitable para salir adelante.El tema de los colores y de los chalecos no me parecen irrelevantes y, aunque el color no existe si es usado como factor de identificaciÃ³n y de pertenencia, al mismo tiempo sirven los colores para distinguir un partido polÃ­tico de otro, sobre todo cuando no hay diferencias polÃ­tica, ideolÃ³gicas, o fÃ¡cticas que les den identidad. Ahora bien, vos venÃ­s de adentro y vas hacia afuera por que venÃ­s de la sociedad y vas hacia un partido que como todo partido, es parte del estado, fuera de la sociedad o frente a ella. Por eso tu color puede ser el de todos y todas aquellas voluntades y espÃ­ritus interesadas en construir la esperanza, esta tambiÃ©n tiene color y en este caso es el del pueblo: plural, sencillo y sabio; sufrido, oprimido pero no sometido, engaÃ±ado, vendido pero de pie; este es el color y el olor de todo aquel que aspire a encarnar y expresar toda esta pesada carga.La derecha del pai­s luce asustada por que toda su economi­a no puede comprar la esperanza y, hoy como nunca,  necesitamos descubrir los caminitos y senderos que llevan al corazon del pueblo. Alla­, al lugar donde se construyen los mejores sueÃ±os y los mas encendidos fuegos. This is a radio segment dedicated to air the issues that affect the Central American Community in the US and abroad. Our radio show challenges main stream media by bringing the voices of the voiceless and those who are forgotten by the the corporate world', '{}'::jsonb, 'fmartin6@yahoo.com', NULL, true),
    (kpfk_station_id, 'On Contact', 'on-contact', 'Chris Hedges weekly interview show ‘On Contact,’ which features “dissident voices” currently missing from the mainstream media. Hedges interviews the black sheep of the establishment.

Chris Hedges is an American journalist, Presbyterian minister, and visiting Princeton University lecturer. His books include Empire of Illusion: The End of Literacy and the Triumph of Spectacle (2009); Death of the Liberal Class (2010); Days of Destruction, Days of Revolt (2012), written with cartoonist Joe Sacco, which was a New York Times best-seller; Wages of Rebellion: The Moral Imperative of Revolt (2015); and his most recent America: The Farewell Tour (2018).', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'CinemaScore', 'cinemascore', 'Fabled classical music host John Santana curates the current form of "classical" music -- film scores from Hollywood and elsewhere -- and interviews with the award-winning composers of such orchestral music.', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'CODEPINK Radio', 'codepink-radio', 'CODEPINK Radio Voices for peace, justice, and resistance worldwide. Friday • 6:00 AM • KPFK 90.7 FM Hosted by CODEPINK (rotating hosts) ▶ Episodes About the Show CODEPINK Radio cuts through the noise with unapologetic, people-powered conversations on peace, justice, and real resistance—right when we need it most. Every Friday morning, you''ll hear grassroots voices from across the globe: organizers fighting U.S. wars, sanctions, and occupation in Yemen, Venezuela, Iran, Palestine, and beyond, alongside local community activists right here at home. This isn''t abstract talk—this is about ending militarism, standing up for human rights, and building a peace economy that puts people over profit. CODEPINK Radio brings you the practical steps and frontline stories the mainstream leaves out, connecting international struggles to local action and holding power to account. If you''re looking for real analysis, true solidarity, and the tools to build a future beyond war, this hour is for you. History & Legacy CODEPINK Radio builds on the foundation of CODEPINK, founded in 2002 as a grassroots movement to protest the U.S. invasion of Iraq and advocate for peace. Over the years, the show has become a dedicated platform for anti-war voices, amplifying women-led organizing, global solidarity campaigns, and urgent calls for justice. CODEPINK''s organizing has helped expose the human impact of U.S. foreign policy—from sanctions and armed interventions to support for whistleblowers and opposition to torture and Guantánamo. The program has been notable for connecting local struggles with global movements, featuring frontline activists from conflict zones and U.S. communities alike. Through ongoing campaigns like Divest from the War Machine, CODEPINK Radio continues to be an anchor for education, accountability, and mobilization against militarism. Hosts & Team View All Hosts (12) ▼ Marcy Winograd Marcy Winograd volunteers as a co-producer of CODEPINK Radio and Empire on the Rocks podcast, co-anchoring the twice-monthly podcast with Medea Benjamin. A retired English and government teacher, Marcy also coordinates CODEPINK''s Drop the ADL campaign and mobilizes for Palestinian rights within teachers'' unions, including United Teachers of Los Angeles and California Teachers Association (CTA). In 2010, Marcy mobilized 41% of the vote in her primary congressional peace challenge to then incumbent Jane Harman. Her activism began in high school when she marched against the Vietnam War and later joined the defense team of Pentagon Papers whistleblower Daniel Ellsberg. Full bio Medea Benjamin Medea Benjamin is a cofounder of both CODEPINK and the international human rights organization Global Exchange. She is the author of 11 books, including Drone Warfare: Killing by Remote Control , Inside Iran , and War in Ukraine . Described as "one of America''s most committed—and most effective—fighters for human rights" by New York Newsday, she was one of 1,000 exemplary women nominated to receive the Nobel Peace Prize. In 2010 she received the Martin Luther King, Jr. Peace Prize from the Fellowship of Reconciliation. Full bio Jodie Evans Jodie Evans is the co-founder of CODEPINK and the after-school writing program 826LA, and serves on the CODEPINK Board of Directors. As Director of Administration in California Governor Jerry Brown''s first administration, Jodie championed environmental causes, resulting in breakthroughs in wind and solar technology. She has produced several documentary films including the Oscar-nominated The Square and climate change documentary This Changes Everything . Jodie is the co-editor of Twilight of Empire and Stop the Next War Now . Full bio Michelle Ellner Michelle is a Latin America campaign coordinator of CODEPINK and producer of CODEPINK Radio and Empire on the Rocks podcast. Born in Venezuela, she holds a bachelor''s degree in languages and international affairs from the University La Sorbonne Paris IV. She worked for an international scholarship program and was sent to Haiti, Cuba, The Gambia, and other countries. Subsequently, she worked with community-based programs in Venezuela and served as an analyst of U.S.-Venezuela relations. Full bio Danaka Katovich Danaka Katovich is CODEPINK''s National Co-Director. She graduated from DePaul University with a bachelor''s degree in Political Science in November 2020. Since 2018 she has been working towards ending US participation in the war in Yemen. At CODEPINK, she oversees all advocacy campaigns and facilitates local organizing in the Midwest and in Europe. Her writing can be found in Jacobin, Salon, Truthout, CommonDreams, and more. Full bio Jenin Jenin is CODEPINK''s Palestine Campaigner. She graduated with a bachelor''s degree in Public Policy from the University of Illinois at Chicago in December of 2023. For over five years, Jenin has been a community organizer focused on the Palestinian movement through advocacy, digital storytelling, and grassroots mobilization. She is a firm believer in intertwined struggle and liberation for all. Full bio Megan Russell Megan Russell is CODEPINK''s China is Not Our Enemy Campaign Coordinator. She graduated from the London School of Economics with a Master''s Degree in Conflict Studies, and attended NYU studying Conflict, Culture, and International Law. Megan spent one year studying in Shanghai, and over eight years studying Chinese Mandarin. Her research focuses on the intersection between US-China affairs, peacebuilding, and international development. Full bio Aaron Aaron is CODEPINK''s War is Not Green Campaigner and East Coast Regional Organizer. Based in Brooklyn, NY, Aaron (they/he) holds an M.A. in Community Development and Planning from Clark University. They worked on internationalist climate justice organizing and Palestine, tenant, and abolitionist organizing. They continue to do this work nationally to combat militarized university repression and produce new modes of solidarity. Full bio Nuvpreet Nuvpreet is CODEPINK''s Digital Content Producer & Bases Off Cyprus Campaign Coordinator, based in London, England. She completed a Bachelor''s in Politics & Sociology at the University of Cambridge, and an MA in Internet Equalities at the University of the Arts London. Her studies focused on racialised surveillance capitalism, with a focus on Artificial Intelligence as a weapon of war and settler colonialism. Full bio Ryan Wentz Ryan Wentz is CODEPINK''s West Coast Organizer. He graduated from University of Colorado Boulder with a bachelor''s degree in Political Science in May 2017. After graduating, he spent six months in Occupied Palestine, doing research on the international weapons trade. He has been active in the antiwar, healthcare justice, and labor movements, and has produced for MintPress News and Empire Files. Full bio Makayla Heiser Makayla Heiser is CODEPINK''s Digital Organizing Assistant. She graduated from Gonzaga University in December 2022 with a bachelor''s in Political Science and double minors in Critical Race Theory and Women''s and Gender studies. Through student organizing with United Students Against Sweatshops, she began to understand the global power of solidarity within the working class and the importance of collective liberation. Full bio Jasmine Butler Jasmine Butler is CODEPINK''s Member & Youth Coordinator. Jasmine (they/them) was born and raised in Memphis by way of deep Mississippi roots. They''re a Black queer writer, cultural worker, and afrofuturist-abolitionist deeply committed to collective liberation through mutual care and education. They are growing as a principled network weaver, educator, historian, and archivist. Jasmine received a B.A. in Geography from Dartmouth College in 2021. Full bio ✉ Contact codepinradio Episodes KPFK Episode Player Support Independent Media Keep radical voices on the air. KPFK runs on community support, not corporate cash. When you give, you''re fueling fearless reporting, frontline stories, and a platform for grassroots action—no censorship, no compromise. Join the movement that keeps independent media alive. Donate today and power real resistance. Contribute', '{"instagram": "https://www.instagram.com/codepinkalert", "twitter": "https://x.com/codepink"}'::jsonb, NULL, 'https://www.codepink.org/jasmine_butler', true),
    (kpfk_station_id, 'Contacto Ancestral', 'contacto-ancestral', 'Programadores / Hosts: Manuel Felipe Pérez, Rubén Rucuch, Alicia Ivonne Estrada, Magdalena Sarat Pacheco, Francisco Aguare, Adel Pérez

email: contacto.ancestral@yahoo.com & contactoancestral@kpfk.org

Website: http://www.myspace.com/contactoancestral', '{}'::jsonb, 'contacto.ancestral@yahoo.com', 'http://www.myspace.com/contactoancestral', true),
    (kpfk_station_id, 'Contragolpe', 'contragolpe', 'Hosts: Jose Benavides and Ricardo Gomez

Contributing hosts: Ruben Luengas Gregorio Luke

Miércoles / Wednesdays 9:30 PM (PST)

Contragolpe es un programa de radio que informa a la comunidad Latina de los acontecimientos que realmente le impactan en su total dimensión. Producido por el experimentado José Benavides, Contragolpe fue creado para despertar la conciencia y la reflexión mediante el combate a la farsa, a la mentira y al mal llamado balance informativo que sólo encubre intereses creados.

Contacto: José Benavides email: jbenavides@kpfk.org Youtube: Conragolpe TV Comparte con nosotros en / Follow us on FACEBOOK Embed not found Embed not found', '{"youtube": "https://www.youtube.com/channel/UCSiKTEunryHCN1PLyLWB5Yg/", "facebook": "https://www.facebook.com/Contragolpeconjosebenavides/"}'::jsonb, 'jbenavides@kpfk.org', NULL, true),
    (kpfk_station_id, 'Conversation Piece', 'conversation-piece', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Cut To The Chase', 'cut-to-the-chase', 'Cut To The Chase Dialogues for justice, solutions, and change. Friday • 8:00 AM • KPFK 90.7 FM Hosted by Sylvester (Sly) Rivers ▶ Episodes About the Show Cut To The Chase gets straight to the real issues—bringing activists, politicians, authors, and everyday thinkers together every Friday morning at 8. Host Sly Rivers cuts through the noise with fearless conversations, live music, speeches, and honest analysis—all sharpened for one purpose: raising consciousness and tearing down injustice, bigotry, poverty, and fear. This is more than talk; it''s a push for action and a call to imagine the world we want. Broadcasting live from the heart of the community, Cut To The Chase gives a platform to grassroots voices and practical solutions. If you''re ready to challenge the status quo and build something better, this is your space. Tune in, wake up, and let''s move forward—together. History & Legacy Cut To The Chase has made its mark as one of KPFK''s few shows to regularly broadcast live from community events, breaking out of the studio to elevate local voices and real-time grassroots action. Over the years, the show has built a reputation for connecting listeners with frontline activists, policy-makers, and people directly impacted by the issues—making space for solutions often overlooked in mainstream media. Its mix of music, speeches, and candid dialogues helps foster both critical analysis and collective consciousness, supporting community efforts to confront injustice and create pathways for meaningful change. Host Sylvester (Sly) Rivers Sylvester "Sly" Rivers is a veteran radio producer, activist, and trusted community voice. With decades spent building movements and lifting up underrepresented stories, Sly brings sharp insight and lived experience to every broadcast. His roots in local organizing and deep commitment to justice shape Cut To The Chase into a direct, people-first conversation every Friday morning—right from the heart of the community he serves. ✉ Contact mornimixcutchasewsylveriver Episodes KPFK Episode Player Support Independent Media Join the movement. When you support KPFK, you fuel truth-telling, tough questions, and real community action—no corporate filters, no watered-down stories. Your gift keeps grassroots voices on the air and helps build the local power we all need. Stand with independent media. Donate now and make change possible. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Dark Star, Dead & Music', 'dark-star-dead-and-music', 'Dark Star, Dead & Music A show devoted to Grateful Dead and beyond Sundays • 8:00–10:00 PM • KPFK 90.7 FM Hosted by Arnella Barbara (Dark Star Gurl) ▶ Episodes About the Show Dark Star, Dead & Music is KPFK''s Sunday night home for Deadheads, music seekers, and anyone drawn to timeless sounds and real community. Host Dark Star Gurl takes you on a fearless radio journey through the legacy of the Grateful Dead, pulsing deep cuts, rare live recordings, and wild musical cousins from every era. This isn''t just a history lesson — it''s a living, breathing gathering place, woven with stories straight from the Deadhead community and tributes that matter. Tune in and find connection, healing, and that one-of-a-kind spark that only people-powered music can deliver. Sundays, 8 to 10 PM, on 90.7 FM — where the music never stops, and you''re always invited. Host Arnella Barbara (Dark Star Gurl) Arnella Barbara, known on air as Dark Star Gurl, is a creative force rooted in Los Angeles—radio host, DJ, production designer, opera singer, and lifelong Deadhead. She''s spent decades building community at the crossroads of art, music, and healing, always with the Grateful Dead as her North Star. Through Dark Star, Dead & Music, Arnella weaves rare grooves, personal stories, and the spirit of unity into a Sunday ritual for dreamers, listeners, and seekers across KPFK''s airwaves. ✉ Contact darkstardeadmusic Episodes KPFK Episode Player Playlists KPFK Playlist - Tabbed Loading playlist... Support Independent Media Keep KPFK wild and free. Your gift fuels radical, independent radio and keeps shows like Dark Star, Dead & Music alive for everyone. When you donate, you power grassroots storytelling and real community—not commercials. Stand with us. Join the circle. Give what you can, and help our music never stop. Contribute', '{"instagram": "https://instagram.com/realarnellabarbaracoco", "facebook": "https://facebook.com/arnellabarbara", "youtube": "https://www.youtube.com/@musicman9067"}'::jsonb, NULL, 'https://www.tiktok.com/@arnella.barbara', true),
    (kpfk_station_id, 'Democracy Now!', 'democracy-now', 'DESCRIPTION: Democracy Now! the War & Peace Report, goes beyond the rhetoric and party politics offered by the mainstream media. Instead, it highlights grassroots efforts to enhance and ignite democracy in the U.S. These days, some are labeling this "public journalism" or "civic journalism." We call it Radio in the Pacifica Tradition.

Democracy Now! focuses on a range of issues that demand attention, from the relationship of citizens to their government to the economic realities of declining wages and standards of living for the vast majority of Americans; from the role of money in campaigns to the impact of new technologies on politics and the media.

Democracy Now! features the ideas and voices of some of the best minds of this generation (and previous ones), including activists, muckrakers, visionaries, artists, risk-takers, academics and "just folks" who share a commitment to truth, democracy, justice, diversity, equality and peace.

The Team includes some of this country''s leading progressive journalists who''ve garnered dozens of awards for their ground-breaking work in radio, television, and print journalism.

Tweets by democracynow Podcast - Democracy Now! with Amy Goodman http://www.democracynow.org/podcast.xml English-language news program. Airs every weekday morning. Democracy Now! En español http://www.democracynow.org/podcast-es.xml Titulares en español cada di­a Democracy Now! Video Broadcast http://www.democracynow.org/podcast-video.xml Daily MPEG4 video broadcast ( experimental ; may not work with all computers or software) Airs every weekday morning. Embed not found

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{}'::jsonb, 'mail@democracynow.org', 'http://www.democracynow.org/podcast-video.xml', true),
    (kpfk_station_id, 'Diálogos de Media Noche', 'dialogos-de-media-noche', 'Dialogos Culturales de Media Noche

Airtime: Thursdays at 11 pm

Producers: Diego de Los Andes, Mario Flores, Henry Prudencio

Hosts: D''Lizza Belen, Alfredo Lopez, Sergio Serdio

Dialogos de Media Noche, ayudando a nuestra comunidad,  con informacion de vivienda, educacion y cultura.

A radio magazine that combines Latino-american poetry, traditional Mexican music and theater in Spanish. We focus in the Los Angeles production. In the format we always go for the live interpretations and Facebook live.

Dialogos Educativos.  Dialogando con Inquilinos    Dialogos Culturales

One hour of live poetry, music and theater. The art and the migrant experience combined in a unique expose in the Los Angeles radio.

Email: serdio@sbcglobal.net

Facebook -

Embed not found', '{}'::jsonb, 'serdio@sbcglobal.net', NULL, true),
    (kpfk_station_id, 'Eco Justice Radio', 'eco-justice-radio', 'Fridays 4pm

EcoJustice Radio presents environmental and climate stories from a social justice frame, featuring voices not necessarily heard on mainstream media. Our purpose is to amplify community voices, broaden the reach of grassroots-based movements, and inspire action. We aim to educate on and provide solutions for social and environmental justice and climate issues that challenge human health and wild landscapes across the USA, and around the world.

Our co-hosts Jessica Aldridge and Carry Kim present a broad range of advocates, including representatives from Black, Indigenous, and People of Color communities; land defenders and water protectors; front/fenceline communities; youth organizers; ecosystem and land stewards; spiritual and faith leaders; documentary filmmakers; climate scientists; and political decision-makers.

EcoJustice Radio is a weekly broadcast produced by SoCal 350 since 2017. Shows are archived at EcoJusticeRadio.org and can be found on all major podcast apps.

EcoJustice Radio Team

Exec. Producer: Jack Eidt @wilderutopia Host/Producer: Jessica Aldridge @AdventuresinWaste Host: Carry Kim Engineer: Blake Lampkin @blakequakebeats Social Media: Natasha Wasim Associate Producer: Emilia Barrosse Created by: Mark and JP Morris

Instagram: https://www.instagram.com/ecojusticeradio_ Facebook: https://www.facebook.com/EcoJusticeRadio or @EcoJusticeRadio Twitter: https://twitter.com/ecojusticeradio or @EcoJusticeRadio

Jessica Aldridge is an environmental educator, community organizer, and waste industry leader. She is a co-founder of SoCal 350, an organizer for @ReusableLA, and founded Adventures in Waste. She has worked for 15 years as a Zero Waste professional, a former professor of Recycling and Resource Management at Santa Monica College, and is a recipient of the inaugural Waste Expo 40 Under 40 award.

Carry Kim, Co-Host

An advocate for ecosystem restoration, indigenous lifeways, and new humanity born of connection and compassion, Carry Kim is a long-time volunteer for SoCal350, member of Ecosystem Restoration Camps, and a co-founder of the Soil Sponge Collective, a grassroots community organization dedicated to big and small-scale regeneration of Mother Earth.

Blake Lampkin, Engineer

Blake “BlakeQuake” Lampkin Is a Los Angeles native Artist who began making music in 2008.  BlakeQuake is not only a record producer but also a DJ, Audio Engineer and Digital Artist. His music can be described as heartfelt stories that take your mind through a journey of deep introspection, while contrasted with hip-hop and other urban influences. BlakeQuake has studied under The Gaslamp Killer and Penthouse Penthouse’s Mike Parvizi . BlakeQuake has worked with the likes of Diana Gordon , Clara the Artist, and many more!

Tweets by EcoJusticeRadio', '{"instagram": "https://www.instagram.com/ecojusticeradio_/", "facebook": "https://www.facebook.com/EcoJusticeRadio", "twitter": "https://twitter.com/EcoJusticeRadio?ref_src=twsrc%5Etfw"}'::jsonb, NULL, 'http://www.ecojusticeradio.org/', true),
    (kpfk_station_id, 'Economic Update', 'economic-update', 'Prof. Richard D. Wolff delivers updates and perspectives on national and international issues, from a pro-socialist, "Democracy at Work" perspective.

Website - http://www.rdwolff.com/

Now airing Wednesdays at 6:30 AM', '{}'::jsonb, NULL, 'http://www.rdwolff.com/', true),
    (kpfk_station_id, 'Edna Tatum''s Gospel Classics', 'edna-tatums-gospel-classics', 'SUNDAYS, 6-8 AM HOST: Gil Fears

EMAIL: guilty2x@gmail.com

Description : - The best in Gospel Music. An uplifting program to get your Sunday going. Audio Archives: https://archive.kpfk.org/index_one.php?shokey=gospelclassics

Gil Fears - Host of “Edna Tatum’s Gospel Classics” has served as co-host for “Gospel Classics” for the past sixteen years. Gil is an ordained Minister and is associated with the Gospel Music Workshop of America. For over 30 years his background in broadcasting includes:

KALI Radio 900 AM, Pasadena (formerly 1430 AM…Hollywood)…Gospel Music /Mornings…

TGN Satelilite TV…Voice Overs &  Jingles

KIPR Radio FM…(Texas) …News, Weather, Sports, & Music (Country)

KLN Radio FM…(Texas)…Morning & Evening Drive (Adult Contemporary)

KTBC Radio (Texas)…Midday News, Weather, & Sports (Adult Contemporary)

Gil has also served as Public Address Announcer for FILA’s NBA Summer Pro League.

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=gospelclassics"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'El Noticiero', 'el-noticiero', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Encuentros con Gregorio Luke', 'encuentros', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Enfoque Latino con Ruben Tapia', 'enfoque-latino-con-ruben-tapia', 'Enfoque Latino Su programa para derrotar la Indiferencia 10 PM (1 hr show) Hosted by Ruben Tapia 🎧 Listen & Archive

Overview Enfoque Latino delivers hard-hitting news and public affairs for Los Angeles''s Spanish-speaking community. Hosted by veteran journalist Ruben Tapia, the show dives into immigration struggles, labor movements, and social justice stories often overlooked by mainstream outlets. Broadcasting late at night, it reaches listeners who work odd hours or crave a deeper connection to their community after dark. Each episode pushes back against indifference, inspiring action and amplifying voices from the frontlines. Enfoque Latino isn''t just a show — it''s a call to stay awake, stay aware, and stay engaged. Immigration Rights Labor & Worker Justice Latin American Politics Community Organizing News & Analysis Interviews Investigative Reports Spanish-speaking Community Activists & Organizers

History & Legacy For many years, Enfoque Latino has been a cornerstone for Spanish-speaking audiences across Los Angeles, offering fearless reporting and community-centered analysis. The show has regularly highlighted immigrant rights movements, local labor organizing, and critical elections shaping the Latino community''s political landscape. It has amplified grassroots movements and given space to voices often erased from mainstream narratives. Under Ruben Tapia''s leadership, Enfoque Latino has become more than just a news program — it''s a living archive of community struggles and triumphs. This legacy continues to inspire and mobilize listeners dedicated to justice and collective power.

Host Ruben Tapia Ruben Tapia is an award-winning journalist and longtime community radio voice, known for his fearless reporting on immigration, labor, and civil rights. With decades of experience covering Spanish-speaking communities in Los Angeles and beyond, he brings deep context and compassion to every story. His work centers the struggles and triumphs of marginalized voices, making Enfoque Latino a vital source of truth and connection. ✉️ Contact Host

enfoque

Recent Episodes KPFK Player v2

Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Donate Now', '{"twitter": "https://x.com/EnfoqueLatino", "facebook": "https://www.facebook.com/PorFavorSiganosEnENFOQUELATINOOFICIAL"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Expansion Zone', 'expansion-zone', 'The Expansion Zone with Sonia Barrett

Email address : info@theexpansionzone.com

Website Link: www.theexpansionzone.com

Facebook: https://business.facebook.com/therealsoniabarrett/

Other links: http://www.therealsoniabarrett.com , http://www.thebusinessofdisease.com

The Expansion Zone explores the human experience from vast perspectives. We examine the life and our quest to understand who and what we are and how we are shaped by invisible principles, belief systems, and conditioning. Through expert guests, we’ll explore the making of our world from quantum physics to parapsychology, health, sociology and philosophy along with practical living. We aim to present profound discovers on human potentials. While the world appears to be in endless turmoil, these dialogs remind us of the possibilities in securing personal change; change that will impact our perception of the world, and the way that we engage with it.  For an hour we’ll stimulate and expand the mind!

https://business.facebook.com/therealsoniabarrett/', '{"facebook": "https://business.facebook.com/therealsoniabarrett/"}'::jsonb, 'info@theexpansionzone.com', 'http://www.thebusinessofdisease.com/', true),
    (kpfk_station_id, 'Feminist Magazine', 'feminist-magazine', 'DESCRIPTION: Feminist Magazine is the weekly Southern California radio show with intersectional feminist perspectives.  Covering stories that you don''t hear on mainstream media!  We broadcast local and global stories, news and opinions about women making a radical difference. We highlight art & culture, and bring you the voices of brilliant feminists who are organizing, making change & kicking ass!

HOST(s): Feminist Magazine is produced & hosted by a coalition of diverse women volunteers. The Feminist Magazine WOMEN''S COALITION: Lynn Harris Ballen, Valecia Phillips, Cherise Charleswell, Karina Elias, Kiyana Williams, Ande Richards, Lucretia Tye Jasmine, Rita Gonzales, Suzette Zazueta

EMAIL: feministmagazine@yahoo.com

WEBSITE & BLOG: http://www.feministmagazine.org

SOCIAL NETWORKS:

Facebook Page: https://www.facebook.com/FeministMagazineKPFK

Facebook Group : https://www.facebook.com/groups/28999708787/

Twitter : @FemMagKPFK

Instagram: @FemMagRadio

ARCHIVES: KPFK Public Radio - Online Archives Archive', '{"facebook": "https://www.facebook.com/groups/28999708787/", "twitter": "https://twitter.com/search?vertical=default&q=%40FemMagKPFK", "instagram": "https://www.instagram.com/femmagradio/", "archive": "http://archive.kpfk.org/index.php?shokey=femmag"}'::jsonb, 'feministmagazine@yahoo.com', 'http://feministmagazine.org/', true),
    (kpfk_station_id, 'FolkScene', 'folkscene', 'FolkScene Playing the best in Folk, Roots, and Americana for over half a century. Sundays • 6:00–8:00 PM • KPFK 90.7 FM Hosted by Allen Larman & Kat Griffin ▶ Episodes About the Show FolkScene is your Sunday night home for the best in Folk, Roots, and Americana—where the songs, stories, and community voices take center stage. Every week, hosts Allen Larman and Kat Griffin bring you new releases, timeless classics, and a live guest interview or performance, inviting you into the ongoing legacy of the grassroots music movement. Since 1970, FolkScene has kept the power of people''s music alive, shining a light on legendary artists and fresh voices who speak truth, celebrate struggle, and foster connection. If you care about music that moves history, honors tradition, and makes space for every story, FolkScene is your show. Tune in Sundays from 6 to 8 pm, only on KPFK. History & Legacy Since its launch in 1970, FolkScene has been a pillar of KPFK and the wider folk music community, preserving and promoting the voices that shape American roots music. Founded by Howard and Roz Larman, the show has continually welcomed legendary and emerging talent—hosting icons like Tom Waits, Joan Baez, The Chieftains, and many more across more than five decades of weekly broadcasts. FolkScene ''s signature blend of artist interviews, live performances, and thoughtfully curated playlists has connected generations of listeners to stories and songs at the heart of social movements and community life. Here''s a treasured shot of Roz, Howard, and Peter Cutler — the heart of FolkScene. Peter has been the show''s engineer/producer since the late seventies, and remains an integral part of FolkScene today. Together, their dedication has kept the spirit of the music alive for generations. Hosts Allen Larman Allen has dedicated decades to sharing the sounds that shape our lives, drawing from deep roots in both music and radio. Raised in the Southern California folk scene, he carries on the tradition begun by Howard and Roz Larman. His on-air warmth and passion connect listeners to the soul of the community and champion independent voices. Kat Griffin Kat brings a love for storytelling and a keen ear for the heart in every song. As a musician, activist, and longtime radio host rooted in LA''s folk circles, she''s tuned in to the everyday struggles and celebrations of real people—a spirit she brings to FolkScene every week. ✉ Contact folkscene Playlists KPFK Playlist - Tabbed Loading playlist...

Support Independent Media Help keep people-powered radio alive. When you support FolkScene on KPFK, you''re fueling independent music, true stories, and a platform where every voice counts. No corporations, no gatekeepers—just a community making radio that matters. Stand with us. Chip in and make a real difference. Contribute', '{"instagram": "https://www.instagram.com/folkscene/", "facebook": "https://www.facebook.com/FolkScene"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Freedom Now', 'freedom-now', 'Freedom Now! is a Pan-African, internationalist world affairs program supporting all indigenous and oppress peoples worldwide.  We support the right to self-determination and seek to provide another point of view, devoid of mainstream media, US/NATO and their allies'' propaganda point of view. We are an anti-imperialist, anti-colonialist program covering the Pan-African diaspora and struggles of oppress peoples worldwide.  All mixed into a global music mix as we also highlight a Los-Angeles Jazz musician every week.  We broadcast our African-Drumbeat Historical calendar recorded by our ancestor, the late Dedon Kamathi (former host). Prolific author/professor/historian of African Studies, Dr. Gerald Horne, Brandon Sankara and Sis Tej co-produce the show, and as always, we stand, READY FOR REVOLUTION!

Facebook:  FreedomNow Gerald Horne

Contact: freedomnow@kpfk.org', '{}'::jsonb, 'freedomnow@kpfk.org', NULL, true),
    (kpfk_station_id, 'Global Village Mondays', 'global-village-mondays', 'Monday 11:00 AM - 1:00 PM With host Kathy Diaz

Join Kathy for an exploration of Afro-Cuban rhythms from around the world and down the block

Kathy brings her long-time experience as host of KPFK''s "Canto Tropical" show to bring you a well curated exploration of Afro-Cuban rhythms from around the world and down the block. She also presents other styles of music from Latin America with other interesting musical stops along the way. And you never know what special guests you might hear or fun facts you might learn on her show.

The Global Village on Facebook

Embed not found

&amp;amp;amp;lt;h2&amp;amp;amp;gt; You need an iframes capable browser to view this content.&amp;amp;amp;lt;/h2&amp;amp;amp;gt;

Previous Playlists: (select date) GV Mon Playlist', '{"facebook": "https://www.facebook.com/globalvillagekpfk/"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Global Village Tuesdays w/Gary Baca', 'global-village-tuesdays', 'Global Village Tuesdays with Gary Baca

Tuesdays, 11:00 AM - 1:00 PM

Baca (aka G-Spot, Mr. G) brings the recording artist into your room for a more intimate, personal talk.  He asks the important questions about music we want to know.  The guests have included Dave Chapelle, Black Eyed Peas, Ziggy Marley, Micky Dolenz (The Monkees), Ray Parker Jr (Raydio), Macy Gray, WAR, Charlie Wilson (Gap band), Johnny Mathis, Boy George (Culture Club), De La Soul, Bootsy Collins (P-Funk), Michael Henderson, Chaka Khan (Rufus), Robin Thicke, Carlos Santana, Sheila E, George Clinton, El Debarge, The B-52’s, Swing Out Sister, Ice Cube, Rakim, The Brothers Johnson, Average White Band, Morris Day & Jerome Benton (The Time)...

Website 4 Audio Archives https://archive.org/details/@the_g-spot_show

gv_tue

Episodes KPFK Episode Player

Playlists KPFK Playlist - Tabbed Loading playlist...

The Global Village on Facebook', '{"archive": "https://archive.org/details/@the_g-spot_show", "facebook": "https://www.facebook.com/globalvillagekpfk/"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Global Village Wednesdays', 'global-village-wednesdays', 'Wednesdays, 11:00 AM - 1:00 PM

Hosts (revolving): Derek Rath, Yatrika Shah-Rais, Betto Arcos, Kevin Lincoln and Maggie LePique

The Global Village on Facebook

gv_yatrika

Episodes KPFK Episode Player

Playlists KPFK Playlist - Tabbed Loading playlist...', '{"facebook": "https://www.facebook.com/globalvillagekpfk/"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Global Village Thursdays w John Schneider', 'global-village-thursdays-w-john-schneider', 'EMAIL: John Schneider: johnoschneider@hotmail.com

DESCRIPTION: Music from around the world and down the block.

The Global Village on Facebook

Embed not found

Listen to archives of this show [ here ]

Current Playlist

Previous Playlists: (select date)', '{"facebook": "https://www.facebook.com/globalvillagekpfk/", "archive": "http://archive.kpfk.org/index.php?shokey=gv_john"}'::jsonb, 'johnoschneider@hotmail.com', NULL, true),
    (kpfk_station_id, 'Global Village Fridays w Sergio Mielniczenko', 'global-village-fridays-w-sergio-mielniczenko', 'Global Village Fridays with Sergio Mielniczenko HOST: Sergio Mielniczenko

Email: sergiobrazilianhour@gmail.com Archives of this show can be found [ HERE ]

DESCRIPTION: Music from around the world and down the block. Sergio says: Free non-stop stream of Brazilian Music hosted by Sergio can be found here: www.brazilianhour.org

To find out about free concerts, summer events, and great music, see the following websites:

Archives of this show can be heard here: https://archive.kpfk.org/index_one.php?shokey=gv_sergio

www.getty.edu www.skirball.org www.grandperformances.org

www.hollywoodbowl.org www.ticketmaster.com www.fordamphitheatre.org

UCLA Royce Hall www.brazilianhour.org www.braziliannites.com www.catalinajazzclub.com www.jazzbakery.com www.zanzibarlive.com www.templebarlive.com

ARCHIVES:

The Global Village on Facebook

Embed not found

Current Playlist

Previous Playlists: (select date)', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=gv_sergio", "facebook": "https://www.facebook.com/globalvillagekpfk/"}'::jsonb, 'sergiobrazilianhour@gmail.com', 'http://www.templebarlive.com/', true),
    (kpfk_station_id, 'Hablando de Sudamerica', 'hablando-de-sudamerica', 'Hablando de Sudamérica discusses issues pertaining to South America, we talk arts politics and culture.

Un programa objetivo, destinado a la audiencia latinoamericana y en especial a la suramericana. Tiene el propósito de informar y llevar los acontecimientos más actualizados de America del Sur en cuanto a su política económica y social. El objetivo principal es acortar la distancia y romper el cerco mediático corporativo al que esta sujeto Latinoamérica en la actualidad.

Lunes 11:30 PM

Producer: Leo Morales

Rotating hosts: Luis Zambrano, Edgar Villavicencio, Angel Jaramillo, Lady Pizzaro

Email: Hablandodesudamerica@KPFk.org ,', '{}'::jsonb, 'Hablandodesudamerica@KPFk.org', NULL, true),
    (kpfk_station_id, 'IMRU Radio', 'imru', 'IMRU Serving the voices of the Queer Community Out Loud and Out Proud since 1974 Monday • 7:00 PM • KPFK 90.7 FM Hosted by Michael Taylor Gray ▶ Episodes About the Show IMRU is KPFK''s long-running queer radio magazine—broadcasting Out Loud and Out Proud since 1974. Every Monday night we bring you voices from across the LGBTQIA2S+ spectrum: frontline activism, art and culture, history, and tough conversations that matter now. Hosted by Michael Taylor Gray, IMRU goes beyond headlines. We amplify citizen journalists, elevate grassroots organizers, and center lived experience—from Southern California to the broader movement. If you want truth, connection, and unapologetic pride, tune in. This is your space. History & Legacy On the air since 1974, IMRU is the single longest-running LGBTQIA2S+ radio program in the world today. Born in the post-Stonewall era, the show has chronicled turning points from the HIV/AIDS crisis to marriage equality and today''s fight for trans rights—while training and elevating community contributors. Through shifting politics and culture, IMRU has remained a living archive and a vital connector for queer life on the airwaves. Hosts Michael Taylor Gray Michael Taylor Gray is a storyteller, producer, and longtime community advocate. An award-winning actor and original cast member of the GLAAD-recognized "Southern Baptist Sissies," Michael uses the mic to amplify authentic queer voices and honor IMRU''s radical legacy each week. Contributors & Community Reporters IMRU is built with community: rotating contributors, citizen journalists, and cultural workers who bring on-the-ground reporting, short features, and interviews from across queer life in Southern California and beyond. ✉ Contact imru Episodes KPFK Episode Player Support Independent Media IMRU isn''t nostalgia — it''s right now. It''s artists, activists, and voices mainstream media ignores. If you believe in lifting up queer stories for today and tomorrow, back the show and be part of the next wave. Contribute', '{"instagram": "https://www.instagram.com/kpfkimru", "facebook": "https://www.facebook.com/imrumedia"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Informativo Pacifica', 'informativo-pacifica', 'Informativo Pacifica Noticias con consciencia. Voice for the people. New Episodes Every Weekday Hosted by Norma Martinez Velazquez ▶ Episodes About the Show Informativo Pacifica delivers fearless Spanish-language news and analysis from Los Angeles to Latin America and beyond. Hosted by journalist and activist Norma Martinez Velazquez, the show centers stories and struggles too often ignored by mainstream media. Each episode tackles urgent headlines — from Palestine and Gaza, to U.S. immigration policies, to labor movements across Argentina and Brazil — always through a lens of social justice, human rights, and collective power. Human Rights Immigration Latin America Environmental Justice News Analysis Interviews Latinx Community History & Legacy Since its launch in the mid-2000s, Informativo Pacifica has served as a critical Spanish-language news source for Los Angeles and beyond. Under the leadership of Norma Martinez Velazquez, the show amplifies stories from immigrant communities, Latin American social movements, labor struggles, and global human rights campaigns. It has covered historic moments like massive immigrant rights marches in LA, uprisings in Latin America, and ongoing fights against state repression worldwide. Informativo Pacifica remains a steadfast platform for truth, dignity, and collective power. Host Norma Martinez Velazquez A journalist and activist dedicated to immigrant rights and human rights advocacy. Norma leads every episode with sharp analysis, compassion, and an unyielding commitment to truth. ✉ Contact informap Episodes KPFK Episode Player Keep This Show On the Air Your contribution helps keep independent, Spanish-language journalism alive on KPFK. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'In The Cut Radio', 'in-the-cut-radio', 'Saturday into Sunday Midnight – 2am

In The Cut Radio – Live From The Launchpad with DJ Ben Vera

DJ Ben Vera brings you a Saturday night extravaganza of sound, blending club cuts with crate digging.  This is the Saturday night party you’ve been looking for.  DJ Ben will sample all flavors of funk, jazz, hiphop, r&b and EDM.  The best way to spend your weekend – dancing and singing along to your favorite jams as well as discovering new future classics.  A good time is all we are after so join us every Saturday night for your entry to the best party on FM radio.  Welcome to In The Cut – Live From The Launchpad with DJ Ben Vera.

Bigo.tv/DJBenVera

@BenVeraOfficial on all social media www.AOTARadio.com

https://www.benveraofficial.com/

Archives Can Be heard HERE

Current Playlist

Previous Playlists: (select date)', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=realrockriffsamprhyth"}'::jsonb, NULL, 'https://www.benveraofficial.com/', true),
    (kpfk_station_id, 'Jazz Sessions', 'jazz-sessions', 'The Jazz Sessions with Dr. Jaz Sawyer Mondays 12am-2am PST

A program that captures the spirit of the jam session and celebrates timeless jazz recordings of then and now. Contact: jaz@jazsawyer.com | IG: kpfkjazzsessions Dr. Jaz Sawyer is an accomplished drummer and educator from San Francisco. Jaz has worked with many notable artists, and can be heard on over 80 recordings both as a leader and sideman. Sawyer is the son of the late former KPFA board member, programmer and longtime advocate Lewis Sawyer Jr. Jaz is deeply rooted in the Pacificia Family gaining early radio experience assisting his dad co-producing and guest hosting throughout the years on KPFA from 2011 through 2017. Jaz joined KPFK in May 2021 and proud to continue the legacy of celebrating the music. Audio Archives of the last two shows can be found HERE

Current Playlist

Previous Playlists: (select date)

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=rise"}'::jsonb, 'jaz@jazsawyer.com', NULL, true),
    (kpfk_station_id, 'LA Review of Books (LARB)', 'la-review-of-books', 'LARB Radio Hour Literature, culture, and conversation from the heart of Los Angeles. Thursday • 2:00 PM • KPFK 90.7 FM Hosted by Medaya Ocher, Eric Newman, Kate Wolf ▶ Episodes About the Show LARB Radio Hour — Every Thursday at 2:00 PM on KPFK 90.7 FM, LARB Radio Hour opens up the world of books, ideas, and urgent conversation from right here in Los Angeles. Hosts Medaya Ocher, Eric Newman, and Kate Wolf—editors at the Los Angeles Review of Books—invite you into candid, searching dialogues with writers, artists, and cultural thinkers shaping today and tomorrow. Each episode is a fresh take: fiction, poetry, philosophy, politics, and creative voices that push boundaries and ask the questions mainstream media misses. This isn''t just literary talk—it''s a space for critical ideas and emerging voices to challenge, inspire, and move us forward, grounded in the realities of one of the world''s most dynamic cities. If you care about culture, justice, and the power of art to spark change, tune in for stories and perspectives that dig deep—always smart, surprising, and fiercely local. History & Legacy Since 2016, LARB Radio Hour has served as a vital platform for writers, artists, and thinkers shaping Los Angeles''s cultural landscape. Emerging from the Los Angeles Review of Books, the show has built a reputation for in-depth, wide-ranging interviews and timely conversations—spotlighting not only established voices but also amplifying emerging talents and underrepresented perspectives. Through its blend of literature, politics, and the arts, LARB Radio Hour has fostered space for dialogue and community, engaging listeners in critical questions often overlooked by mainstream media. Its commitment to intellectual curiosity and local storytelling has made it a trusted resource for anyone interested in the forces transforming both the city and the wider world. Hosts Medaya Ocher Medaya Ocher brings sharp insight and genuine warmth to every conversation, connecting L.A.''s creative scene through bold, searching interviews. Eric Newman An Editor-at-Large for LARB and scholar of literature and queer theory, Eric''s interviews often explore identity, politics, and the shifting landscape of cultural power. Kate Wolf Also an Editor-at-Large at LARB, Kate''s background as a critic and artist shapes her keen attention to aesthetics, voice, and the inner lives of her guests. ✉ Contact larb Episodes KPFK Episode Player Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Contribute', '{"instagram": "https://instagram.com/lareviewofbooks", "twitter": "https://x.com/LAReviewofBooks"}'::jsonb, NULL, 'https://lareviewofbooks.org/podcasts/larb-radio-hour', true),
    (kpfk_station_id, 'L.A. Theatre Works', 'l-a-theatre-works', 'L.A. THEATRE WORKS

Producing Director:  Susan Albert Loewenberg

Website: http://latw.org

Contact info:

Box Office: 310.827.0889 Email: latw@latw.org Audio Sales: 310.827.0808 ext. 221

Offices: 681 Venice Blvd., Venice, CA 90291; Phone (310) 827-0808, Fax: (310) 827-4949

Live Recordings at UCLA James Bridges Theatre

Weekly broadcast available for streaming for one week only at http://latw.org

LATW''s mission is to record and preserve great performances of important stage plays, using new technology to make world-class theatre accessible to the widest possible audience, and to expand the use of theatre as a teaching tool.

LATW was founded in 1974 to give voice to underrepresented groups, bring attention to new plays and playwrights, and produce plays that address critical historical, cultural and social issues. In the 1990''s, LATW embraced audio recording in lieu of conventional theatrical presentation. Today, LATW is the nation''s leading producer of audio theatre. We produce world classics, modern masterpieces, contemporary and original works that speak to the issues of our times.

Home to the largest collection of professionally produced audio theatre in the country, LATW builds on this unique resource with an evolving range of programs that bring an immersive theatre experience to a diverse audience regardless of geographic and economic barriers, including:

• Live Series: Held at UCLA''s 278-seat James Bridges Theater, the Live Series presents radio-theatre style live performances of classic and new plays with award-winning actors.', '{}'::jsonb, NULL, 'http://latw.org', true),
    (kpfk_station_id, 'La Raza Radio', 'la-raza-radio', 'La Raza Radio Radio for la raza, la causa, la gente de Aztlan Thursday • 3 PM • KPFK 90.7 FM Hosted by Matt Sedillo and Gary Baca ▶ Episodes About the Show We start with history and economics. We take direction from the demands of the people and the movement. Every Thursday, that means Chicanismo, internationalism, working class struggle—news and views from a Chicano perspective. Organizers, writers, and activists talking about the fights that actually matter. An hour of strength and dignity. Welcome to La Raza Radio. Hosts Matt Sedillo Matt Sedillo is an internationally renowned poet who has read in 15 countries and been translated into 9 languages. He''s been called the best political poet in America by investigative journalist Greg Palast and the "poet laureate of struggle" by historian Paul Ortiz. Matt has spoken at the San Francisco International Poetry Festival, the Texas Book Festival, and Casa de las Americas in Havana. He runs a weekly writers workshop at Re/Arte Centro Literario in Boyle Heights and is the literary director at dA Center for the Arts in Pomona. Gary Baca Gary Baca has over 20 years in radio, starting at Laney College in 1988 before moving to KALX Berkeley and then KPFK Los Angeles. He''s interviewed everyone from James Brown and Carlos Santana to Gil Scott-Heron and Ice Cube—plus deep archive conversations with artists like Maurice White, Rick James, and Teena Marie. As a kid, he''d wait for hours hoping to hear his favorite artists get interviewed. He never did, so he started doing it himself. ✉ Contact morningmradiojaguar Episodes KPFK Episode Player Keep This Show On the Air La Raza Radio runs on listener support. Your donation keeps Chicano voices, history, and politics on the air every Thursday. If this show matters to you, help us keep it going. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'The Lawyer''s Guild with Jim Lafferty', 'lawyers-guild', 'The Lawyers Guild Show Where movement leaders speak and truth is aired Wednesdays • 3:00 PM • KPFK 90.7 FM Hosted by Jim Lafferty and Maria Hall ▶ Episodes About the Show The Lawyers Guild Show — Every week on The Lawyers Guild Show, Jim Lafferty and Maria Hall bring on the voices driving change in our city and across the country. From movement organizers to authors, filmmakers, and investigative journalists, this is the place where the people on the front lines speak for themselves — breaking down the headlines and sharing the real work behind the fight for justice. If you want to hear from the folks actually building new futures, not just those talking about it, you''re in the right place. Unfiltered, unapologetic, and always rooted in community, The Lawyers Guild Show connects you to the struggles and strategies making history now. Wednesdays at 3, only on KPFK — tune in for news that matters and voices that won''t be silenced. History & Legacy For decades, The Lawyers Guild Show has been a fixture on KPFK, amplifying the voices of grassroots organizers, legal advocates, and movement leaders pushing for justice. Originating from the Los Angeles chapter of the National Lawyers Guild, the show has tracked critical turning points in local and national activism—from antiwar struggles and immigrant rights mobilizations, to historic legal challenges and frontline community defense. Through in-depth interviews and community-driven analysis, hosts Jim Lafferty and Maria Hall have connected listeners to movements making history, offering a consistent platform for underrepresented voices and urgent issues often sidelined by mainstream media. The show''s legacy is rooted in direct engagement with the people powering social change, building intergenerational trust with activists, organizers, and listeners committed to justice. Hosts Jim Lafferty Jim Lafferty is a lifelong activist and the Executive Director Emeritus of the National Lawyers Guild in Los Angeles. From marches against the Vietnam War to fighting for justice today, Jim''s leadership has shaped the city''s legal and social justice landscape for decades. He brings hard-won perspective and deep roots in Los Angeles movements to every conversation, connecting listeners to history and ongoing struggles. Maria Hall Maria Hall is a civil rights attorney, past co-chair of the National Lawyers Guild in Los Angeles, and director of the Los Angeles Incubator Consortium, supporting solo community lawyers. Maria brings a frontline focus to every show — sharing real stories from her work in the city''s neighborhoods and always centering people and movements driving change. ✉ Contact lawyersguild Episodes KPFK Episode Player Support Independent Media KPFK is powered by people, not corporations. Independent voices like The Lawyers Guild Show only exist because community members like you step up and support radical media. Your donation keeps grassroots stories, uncompromising truth, and frontline perspectives on air—free from big money interests. Join the movement. Chip in today and help us keep the signal strong for everyone fighting for justice. Contribute', '{"instagram": "https://www.instagram.com/nationallawyersguild/?hl=en", "facebook": "https://www.facebook.com/NLGLosAngeles"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Living In The USA', 'jon-wiener', 'Jon Wiener Wiener@uci.edu 310-558-0132 www.JonWiener.com Shows archived at Apple podcasts @jonwiener.bsky.social “Living In The USA” with Jon Wiener: talking about politics, thinking about the Left. News, commentary and analysis about the resistance to Trump. Fridays at 4:00 PM.', '{}'::jsonb, 'Wiener@uci.edu', 'https://bsky.app/profile/jonwiener.bsky.social', true),
    (kpfk_station_id, 'Middle East in Focus', 'middle-east-in-focus', 'Middle East in Focus News and views on the Middle East and relevant U.S. foreign policy. Sundays • 1:00 PM • KPFK 90.7 FM Hosted by Estee Chandler and Nagwa Ibrahim ▶ Episodes About the Show Middle East in Focus cuts through noise and distortion to deliver the news and views on the Middle East that mainstream media won''t touch. Every Sunday at 1pm, hosts Nagwa Ibrahim and Estee Chandler bring you the voices, stories, and resistance movements shaping the region—putting people, not propaganda, at the center. The show goes beyond headlines, breaking down U.S. foreign policy, media bias, and the real impact on everyday lives in southwestern Asia. By challenging stereotypes and amplifying truth from lived experience, Middle East in Focus builds real solidarity across borders and communities—arming listeners with context, clarity, and the power to think for themselves. If you want honest coverage that empowers the people most affected, this is your station and your show. History & Legacy Since its launch in 1980, Middle East in Focus has stood as one of KPFK''s longest-running programs, founded during the Iran hostage crisis to provide critical coverage of Middle Eastern affairs absent from mainstream U.S. media. Over the decades, a diverse continuum of producer-host teams—beginning with Michel Bogopolsky and Sarah Mardell, and later including figures like Judith Gabriel, Don Bustany, Moneim Fadali, MD, and Tamadur Alaqeel—have sustained the show''s commitment to centering authentic voices, historical context, and grassroots movements. The program has persistently challenged prevailing media narratives, highlighting nonviolent resistance and stories overlooked or misrepresented elsewhere. Its legacy is marked by fostering deeper public understanding and solidarity, equipping listeners to engage critically with U.S. policy and the lived realities of people across southwestern Asia. Hosts Estee Chandler Estee Chandler grew up in Southern California where her work in the film industry, on both sides of the camera, spans more than thirty years. Her political and civic work took on a new urgency in 2001 after the US Supreme Court ruled that the state of Florida must stop counting the votes in their 2000 Presidential election. In 2010 she launched a Los Angeles chapter of Jewish Voice for Peace (JVP), which is the largest progressive, Jewish, anti-Zionist organization in the world. JVP organizes our grassroots, multiracial, cross-class, intergenerational movement of U.S. based Jews into solidarity with the Palestinian freedom struggle, guided by a vision of justice, equality, and dignity for all people. She currently serves as the Board Chair of JVP''s sister organization JVP Action. Nagwa Ibrahim Nagwa Ibrahim is an attorney and filmmaker whose life''s work centers on defending human rights and telling the multidimensional stories of humanity to connect us beyond borders. She is currently the Legal Director at a national nonprofit organization that represents survivors of human trafficking, where she leads a team of attorneys providing direct legal services to the largest number of survivors of human trafficking in the United States, as well as training and technical assistance on human trafficking cases nationwide. Prior to this role, Nagwa was in private practice with a focus on immigration law and criminal defense, and has also worked as a civil and human rights attorney handling Guantánamo and other prisoner rights cases. Nagwa graduated from UCLA School of Law with a specialization in Critical Race Studies. Deeply connected to struggles both at home and abroad, Nagwa brings humanity, curiosity, and a global perspective to every conversation on Middle East in Focus . ✉ Contact meif Episodes KPFK Episode Player Support Independent Media Independent, people-powered media matters. Every broadcast of Middle East in Focus breaks through corporate noise to give voice to those silenced and to movements for justice. Your support keeps truth on the air and community at the heart of every story. Stand with us—be part of the change and help keep KPFK strong. Donate today, and together we''ll keep real stories alive. Contribute', '{"twitter": "https://x.com/MidEastInFocus"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Midnight Snack', 'midnight-snack', 'Take a listen Friday into Saturday at Midnight, its “Midnight Snack'' DJ @danimamath will keep you up and moving with a blend of house, electro pop, and everything in between. Satisfy your late night cravings with Dani Mamath from 12-2AM! #newshow #kpfk #peoplepowered #tunein #listenonline @danimamath

Email: djdanimamath@gmail.com

Instagram: https://www.instagram.com/danimamath/

Audio archives can be heard HERE

Latest Playlist

Previous Playlists: (select date)', '{"facebook": "https://www.facebook.com/hashtag/listenonline?__eep__=6&__cft__[0]=AZWSeFwFdDG00AUjWu-YiabttoX80De1C0sebY3oo6rD9htzuBd68Lo60tfXttLMwYbOMzDMmsjsfNt4U_zUUoPU2g-uqtBceYejnXkVyxQcsi0seWcZnkgxELOtbVOXLfqz-wi6REbXnZhnntd0Cz-S&__tn__=*NK-R", "instagram": "https://www.instagram.com/danimamath/", "archive": "https://archive.kpfk.org/index_one.php?shokey=deepend"}'::jsonb, 'djdanimamath@gmail.com', NULL, true),
    (kpfk_station_id, 'Musiqueros y Juventud', 'musiqueros-y-juventud', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Nightscapes', 'nightscapes', 'Late Night Music Programming Sundays 4:00 am - 6:00am

Your hosts: Jillian Rise

Contact Host Jillian: nightscapesradio@aol.com

Alternates with Due Diligence. Giving you the music to make you think, feel, expand your dreams, reach for the stars and grow your mind. Playing an eclectic blend of low-fi, chilled out neo-soul, jazz, rock, blues, and a few classics. No holds barred, anything goes--DJ Jillian Rise

Embed not found

Current Playlist

Previous Playlists: (select date)', '{}'::jsonb, 'nightscapesradio@aol.com', NULL, true),
    (kpfk_station_id, 'Nuestra Voz', 'nuestra-voz', 'Mesa redonda de información, análisis y cultura "Donde su voz es la que cuenta"

Nuestra Voz: Programa de informacion, cultura, salud y educación. "Donde su voz es la que cuenta"

Nuestra Voz: Program on current Latin American events, culture, health & education. Topics include environment, politics, education, health, human rights and international issues. Open phone lines, calls welcome @ (818) 985-5735.

Part I - Thursdays, 8:30 - 9:00 PM Actualidad

Producer and Host: Freya Rojo & Jeannete Charles

Part II - 9:00 - 9:30 PM Programación Cultural

Producer and Host: Leonardo Lorca & Diego De Los Andes

Part III - 9 : 30 - 10:00 PM Salud y Educación

Producer and Host: Lili Lopez-Sunn & Ana Laura Villagrana

Coordinators: Freya Rojo, Leonardo Lorca & Lili Lopez-Sunn Executive Producer: Leonardo Lorca

Send us an email to:

nuestravozkpfk@gmail.com

Este programa puede ser escuchado en podcast: PODCAST

Archivos también se puede encontrar [ aquí ]

Follow us at:

Instagram: @nuestravozkpfk

Facebook:

Embed not found

Twitter:

Tweets by nuestravozkpfk', '{"archive": "http://archive.kpfk.org/index.php?shokey=nuestravoz", "twitter": "https://twitter.com/nuestravozkpfk?ref_src=twsrc%5Etfw"}'::jsonb, 'nuestravozkpfk@gmail.com', NULL, true),
    (kpfk_station_id, 'The Out Agenda', 'the-out-agenda', 'HOSTS: Rita Gonzales, Chris Coleman, Teresa Garay and Ralph Radebaugh Producer/Executive Producers: Rita Gonzales, Chris Coleman, Teresa Garay and Ralph Radebaugh Community Liaison: Rita Gonzales

Download, Listen, Podcast [ HERE ] EMAIL: theoutagenda@kpfk.org

TWITTER: @ theoutagenda

FACEBOOK : Facebook/theoutagenda

DESCRIPTION: Through interviews, debates, and special feature stories, this show examines today’s issues from the LGBT perspective.  Each week, listeners are invited to be active participants in the show with call ins, by posting comments on Facebook, or with emails and tweets.  The OUT Agenda is truly the voice of the LBGT community in action.

Tweets by theoutagenda

Embed not found', '{"archive": "http://archive.kpfk.org/index.php?shokey=outagenda", "twitter": "https://twitter.com/theoutagenda?ref_src=twsrc%5Etfw"}'::jsonb, 'theoutagenda@kpfk.org', NULL, true),
    (kpfk_station_id, 'Pacifica Performance Showcase', 'pacifica-performance-showcase', 'PACIFICA PERFORMANCE SHOWCASE, arts & culture to enlighten, enliven and educate with host Donna Walker, covers the best in film, theatre, music, and the arts.

Archives of this show can be heard here - https://archive.kpfk.org/index_one.php?shokey=pperf

Email: dwalker@kpfk.org

Facebook:

Embed not found', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=pperf"}'::jsonb, 'dwalker@kpfk.org', NULL, true),
    (kpfk_station_id, 'Perspectiva de las Americas', 'perspectiva-de-las-americas', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Phil and Ted’s Sexy Boomer Show', 'phil-and-teds-sexy-boomer-show', '"Phil and Ted’s Sexy Boomer Show" is a free-form, comedy/talk podcast co-hosted by long-time collaborators and Pacifica Radio veterans, Phil Proctor and Ted Bonnitt, and featuring special guests and Hollywood stars in fun and deep conversations. Phil Proctor is an accomplished humorist, author, actor, and best known as a founding member of the groundbreaking comedy group, The Firesign Theatre which got its start on KPFK. Ted Bonnitt is a writer, host and producer of national entertainment podcasts, radio, television and film programming, including with members of the Firesign Theatre. Ted hosted the "The Bernie Fleshkin Show" on WBAI for 10 years.

Previous episodes can be heard here: https://sexyboomershow.libsyn.com/

Facebook: https://www.facebook.com/SexyBoomerShow

Twitter:

Tweets by BoomerSexy', '{"facebook": "https://www.facebook.com/SexyBoomerShow", "twitter": "https://twitter.com/BoomerSexy?ref_src=twsrc%5Etfw"}'::jsonb, NULL, 'https://sexyboomershow.libsyn.com/', true),
    (kpfk_station_id, 'Pocho Hour of Power', 'pocho-hour-of-power', 'BEST OF L.A. /// ARTS & ENTERTAINMENT /// 2016

LA WEEKLY: ADAM GROPMAN

While L.A.''s 90.7 KPFK, part of the Pacifica Radio Network, is not generally known for humor or colorfully exuberant personalities, there are a few exceptions, and the Pocho Hour of Power is a notable one. Billing itself as "the nation''s only English-language, Latino-themed political satire program," the show and its hosts — Lalo Alcaraz, Jeffrey Keller, Patrick Perez and Esteban Zul — along with producer Gary Baca and music DJ Boxy Dee, maintain a sense of freewheeling fun, deftly weaving thoughtfully respectful discussions on art, politics and personal anecdotes with a vibe of controlled chaos bordering on merry pranksterism. Together they''re a kind of super team, fusing Latino consciousness with the broader landscape of L.A. and the world, bringing in acclaimed artists, writers, comedians and activists as guests for an hour that''s poignant, funny and fast-paced.

Fridays at 3 PM

News, Music, Comedy & Cultural Arts Variety Show & "Non-Stop Afternoon Party". Guests include: International & Local Journalists, News-Makers, Documentary Film Directors, Activists, Actors, Writers, Comedians, Musicians, Poets and In-Studio Guests.

Los Angeles Pacifica Radio KPFK 90.7 FM is home to the most raucous, irreverent and politically smart radio talk show anywhere, the L.A.-based Spanglish-slinging Pocho Hour of Power. Co-hosted by nationally syndicated daily newspaper cartoonist and comedian Lalo Alcaraz, satirist and filmmaker Esteban Zul, comedian/actor Jeff Keller and wild improvista (often seen on MADtv) Paul Vato, with producer Gary Baca the volatile breakout hit show has attracted a vast audience, star guests and IRS scrutiny. On any given Pocho Hour of Power you can hear satirical radio sketches, politically charged parody songs and even serious public affairs segments.

Producer: Gary Baca - gbaca@kpfk.org

www.pocho.com

Email: ThePochoHourOfPower@KPFK.ORG

Lalo Alcaraz Nationally syndicated political cartoonist, and creator of La Cucaracha, the daily comic strip + radio host @ LA''s KPFK Radio 90.7 FM''s Pocho Hour of Power www.pocho.com

Alcaraz is known for being the author of the comic La Cucaracha , the first nationally syndicated, politically themed Latino daily comic strip. Launched in 2002, La Cucaracha has become one of the most controversial in the history of American comic strips. He is also the creator of "Daniel D. Portado", a satirical Latin character who in 1994 called on Mexican immigrants to return south—"reverse immigration"—as a response to the controversial Proposition 187 .

A leading figure in the Chicano movement , Alcaraz formerly contributed political cartoons for LA Weekly from 1992 to 2010. He co-hosts a radio show on KPFK called the "Pocho Hour of Power." He also contributed a work of art to the 2008 Obama campaign called "Viva Obama".  He recently taught as a faculty member at Otis College of Art & Design .  Alcaraz was also Consulting Producer and Writer on the Seth MacFarlane–executive produced animated show (created by Family Guy show runner Mark Hentemann) Bordertown , which ran one 13-episode season on Fox. It featured the first animated Mexican-American or even Latino family on primetime American television. Lalo also served as producer along with Gustavo Arellano on comedian Al Madrigal''s TV special for Fusion, Half Like Me . Alcaraz also consults on films, including Pixar''s Coco (2017).  He is also a TV animation producer and consultant at Nickelodeon . Alcaraz is also a performer, performing as an angry mariachi in Pixar''s "Coco" (2017) and has portrayed a Mexican bounty hunter named "Royce Vargas" in the Bill Plympton /Jim Lujan animated feature film, Revengeance (2017).

In addition to the daily strip, Alcaraz has published 4 books, La Cucaracha (Andrews McMeel Publishing, 2004), Migra Mouse: Political Cartoons on Immigration (RDF Books, 2004), "Latino USA: A Cartoon History", (Basic Books 2000), also the 15th Anniversary Edition of Latino USA and "A Most Imperfect Union", (Basic Books 2014), another history book in collaboration with Ilan Stavans. Alcaraz is also an active speaker on the college circuit. He is represented by The Agency Group in Los Angeles.

Lalo Alcaraz is "Jefe-in-Chief" of POCHO.COM, a website specializing in "Ñews y Satire".

Awards

Alcaraz has received five Southern California Journalism Awards for Best Cartoon in Weekly Papers, and numerous other awards and honors, including "The Latino Spirit Award" from the California Legislature and the Office of the Lt. Governor, honors from the Los Angeles City Council, The California Chicano News Media Association, the UC Berkeley Chicano Latino Alumni Association, the United Farm Workers of America, the Los Angeles County Federation of Labor, the Center for the Study of Political Graphics, and The Rockefeller Foundation.

Jeffery Keller

@Mymomswhite

Comedian/ Writer and co-host of the Pocho Hour of Power on KPFK 90.7 FM.

An ex NFL player, Keller played football at Washington State from 1978 to 1981 and drafted 11th round 1982 Atlanta Falcons

Keller can be seen performing his stand up at various comedy spot’s in Southern California such as the Ice House.  At a young age Keller was influenced by comedian’s Richard Pryor and Paul Mooney.  He is currently acting and writing for TV and movies.  Keller lives in Hollywood and grew up in Los Angeles, Baldwin Park area.

Esteban Zul was a founding member of the rap group Aztlan Nation from Berkeley, California.  He was introduced to Alcaraz through Pocho producer Gary Baca and along with Alcaraz published Pocho Magazine, thus creating the Pocho Hour of Power.  As of now, Zul is a world traveler and currently writing for movies.

Producer: Gary Baca

aka G-Spot was born and raised in East Oakland. Baca began his radio career at KALX Berkeley before initiating his radio programming at KPFA Berkeley which then lead him to KPFK Los Angeles. In previous radio programs, Baca’s featured presentations have included interviews with Lisa Lisa, Rick James, Morris Day & The Time, George Clinton, Boy George, Tito Puente, Macy Gray, Roger Troutman & Zapp, Bootsy Collins, WAR, James Brown and Cameo, Rakim, The Commodores, Buddy Miles, The Doors, Earth, Wind & Fire, Johnny Mathis and Carlos Santana. Now celebrating 30 years of radio programming, he is also a concert emcee introducing such acts as Ice Cube, Cameo, Cypress Hill, DJ Quik, Too $hort, E40, Tierra, Malo, The Dramatics, Rappin 4Tay, & Sheila E.

KPFK 90.7 FM''s Pocho Hour of Power provides a smartly satirical look at political issues facing Latinos in America. Co-hosted by cartoonist Lalo Alcaraz, filmmaker Esteban Zul, comedian’s Jeff Keller, Paul Vato, and producer Gary Baca the show brings its raucous brand of satire.', '{"twitter": "https://twitter.com/Mymomswhite"}'::jsonb, 'ThePochoHourOfPower@KPFK.ORG', 'https://pbs.twimg.com/profile_images/999711458949713920/_t8tU_A0.jpg', true),
    (kpfk_station_id, 'Profiles with Maggie LePique', 'profiles', 'Profiles The music, artistry, and legacies of the artists who defined an era. First Friday of the Month • 7 PM • KPFK 90.7 FM Hosted by Maggie LePique ▶ Episodes About the Show Profiles is a monthly deep dive into the musicians and artists who broke boundaries and changed the culture. Host Maggie LePique sits down with archivists, producers, and people who knew the legends firsthand—exploring the music, the stories, and the legacies that still resonate. First Fridays at 7 PM. Host & Producer Maggie LePique Maggie LePique has been on the radio since the 1980s, when she was spinning bebop and Kansas City jazz on KCUR in the midwest. She moved to LA and became a traffic reporter, winning an LA Broadcaster''s Award for her live coverage of the 1992 uprising. She was a regular on The Real Don Steele show on K-Earth 101. Maggie returned to music as KPFK''s music director, hosted Global Village from 2003–2009, and now serves as the station''s interim General Manager, Music Director, and Promotions Director. Profiles is her latest project—an in-depth look at the artists who shaped a uniquely creative era. Andrea Love Andrea Love is a rock turntablist and media producer based in Los Angeles. She got her start at WWBN in Flint, Michigan, then hosted "Real Rock Radio" on KPFK. Andrea trained at the Beat Junkie Institute of Sound and now mixes, scratches, and loops at venues like The Whisky A Go Go and The Viper Room—she''s even opened for Robby Krieger of The Doors. As producer of Profiles, she''s helped bring interviews with Serj Tankian, Stanley Clarke, and Jackson Browne to air. ✉ Contact From the Show ‹ With jazz legend Horace Silver With Jackson Browne With Richie Havens With John McDermott (Experience Hendrix) and Eddie Kramer (Jimi''s engineer) With LeRoy Downs and Christian McBride With Andy Garcia › rockprofile Episodes KPFK Episode Player Playlists KPFK Playlist - Tabbed Loading playlist... Keep This Show On the Air Profiles exists because listeners like you support KPFK. Help us keep music history on the air. Contribute

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{"instagram": "https://www.instagram.com/maggielepique/"}'::jsonb, NULL, 'https://www.buzzsprout.com/1798623/episodes', true),
    (kpfk_station_id, 'QR Code', 'qr-code', 'The QR Code Culture. Opinions. Dialogue. Entertainment. Mon–Thu • 6:00–7:00 AM • KPFK 90.7 FM Hosted by Q Ward & Ramses Ja ▶ Episodes About the Show The QR Code is a fast-paced morning show that brings honest conversation and cultural context to the airwaves. Hosted by Q Ward and Ramses Ja—the duo behind the nationally syndicated Civic Cipher—the show unpacks stories and issues that matter to Black and Brown communities and the broader American public. From politics and social justice to education, media, mental health, and identity, The QR Code offers perspective with purpose. CODE stands for Culture, Opinions, Dialogue, Entertainment—the pillars of every episode. The show is rooted in truth, driven by lived experience, and committed to transparency as a tool for collective growth. "We believe that truth and transparency are essential to a healthy democracy, and that real change starts with real conversations." — Ramses Ja "When people share stories that reflect their lived experience, walls come down and real dialogue begins." — Q Ward Whether you''re a longtime Civic Cipher listener or just tuning in, The QR Code is your daily reset. About Civic Cipher Before launching The QR Code, Q Ward and Ramses Ja created Civic Cipher—a nationally syndicated radio show focused on racial justice, civic engagement, and amplifying marginalized voices. The show continues to air weekly in multiple cities and informs the mission behind The QR Code. Meet the Hosts Q Ward Q Ward is a community organizer, educator, and public speaker known for fostering honest conversations around race, identity, and equity. With a calm, thoughtful presence, Q creates space for people to share their stories and connect across divides. @iamqward Ramses Ja Ramses Ja is a DJ, activist, and media strategist who believes in the power of storytelling to shift culture. His work centers on media literacy, racial justice, and uplifting voices that are often left out of the mainstream narrative. @ramsesja ✉ Contact qrcode Episodes KPFK Episode Player Keep the Conversation Going Real change starts with real conversations—and those conversations need your support. Help keep The QR Code and KPFK on the air. Contribute', '{"instagram": "https://instagram.com/ramsesja"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Que Pasa en Los Angeles?', 'que-pasa-en-los-angeles', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Radio Bilingue', 'radio-bilingue', 'Edición Semanaria de Noticiero Latino and Línea Abierta (A Segment.)

Email : Maria de Jesus Gomez / chuyag@radiobilingue.org

Edición Semanaria, a weekly Spanish-language news magazine Línea Abierta, national Spanish-language talk and call-in program.

· Host, Aura González

· Producer, Rubén Tapia

· Production Assistant, María de Jesús Gómez

· Technical Engineer, Jorge Ramirez

· News Director, Samuel Orozco

· Wednesday 11:30 PM

Website: www.radiobilingue.org

Social Media Links :

Edición Semanaria is a weekly 14-minute Spanish-language news magazine, on air since 1993 and the only of its kind in the nation. Vibrant three- to five-minute features explore top stories of the week, human interest and arts from communities around the U.S.  Listeners may hear a feature from our “Raices” series on traditional and new interpretations of folk arts of the Americas; from our “Emerging Landscapes” series on Native American – Latino environmental connections; an investigation from our Immigration Desk, a hands-on look at how to navigate the new health law, and profiles of Latino legends and everyday heroes.

Línea Abierta is the first — and only — national live talk and call-in program in public broadcasting interconnecting Spanish-speaking audiences and newsmakers throughout the United States and Mexico.  Each weekday, since 1995, Línea Abierta offers an hour of news, analysis, features, interviews, round-tables, special series and listener call-ins on current events, health, jobs, politics, the environment, education, the arts and culture, race relations, immigrant rights, and more.', '{"facebook": "https://www.facebook.com/radiobilingue/", "twitter": "https://twitter.com/radiobilingue?lang=en", "instagram": "https://www.instagram.com/radiobilingue/"}'::jsonb, 'chuyag@radiobilingue.org', 'http://www.radiobilingue.org', true),
    (kpfk_station_id, 'RADIO INSURGENCIA   FEMENINA', 'radio-insurgencia-femenina', 'Español- Radio Insurgencia Femenina   Martes (9:30-10:30PM) Alternando con Arabaleros de Magon https://www.facebook.com/rif.kpfk/ Radio Insurgencia Femenina es un programa de radio para mujeres que se transmite cada 15 dias. Nos enfocamos en noticias no corporativas, activismo, temas que afectan el bienestar social y emocional de las mujeres latinas, chicanas e indígenas. También traemos arte y cultura a nuestro programa para elevar el talento y dar voz a cientos de mujeres increíbles en todo nuestro continente. English - Radio Insurgencia Femenina  Tuesdays (9:30-10:30PM)

Alternating Tuesdays w Arabaleros de Magon https://www.facebook.com/rif.kpfk/

Radio Insurgencia Femenina is a women''s radio program which airs every other Tuesday. We focus on non corporate news, activism, issues affecting latina, chicana and indigenous women; social emotional well being of women. We also bring art and culture to our program to uplift talent and give voice to hundreds of amazing women throughout our continent.

Embed not found', '{"facebook": "https://www.facebook.com/rif.kpfk/"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Ralph Nader Radio Hour', 'ralph-nader-radio-hour', 'Ralph Nader Radio Hour Resisting corporate power and defending democracy Thursday • Afternoon • KPFK 90.7 FM Hosted by Ralph Nader and Steve Skrovan ▶ Episodes About the Show Ralph Nader Radio Hour — Every week on the Ralph Nader Radio Hour, legendary activist Ralph Nader and a fearless team of co-hosts take on corporate power and government corruption, cutting straight to the core of what''s shaking our democracy. No smoothing over, no corporate filter—just urgent, people-first conversations with citizen advocates, watchdogs, and the voices most ignored by the mainstream. Born right here at KPFK, this show is a frontline for truth-telling and accountability, lifting up organizers, grassroots leaders, and movement-builders fighting for justice in your backyard—and across the country. If you care about holding power to account, protecting your rights, and hearing the news that actually matters, tune in every Thursday afternoon. This is public radio with its sleeves rolled up. History & Legacy Launched in early 2014 from KPFK, the Ralph Nader Radio Hour began as an impromptu interview with Ralph Nader that quickly evolved into a weekly forum for challenging corporate power and uplifting citizen activism. Over 600 episodes later, the show has delivered more than a thousand interviews, featuring both prominent progressives—like Noam Chomsky, Phil Donahue, and Rev. William Barber—and countless grassroots organizers, authors, and advocates often excluded from mainstream media. Staying true to KPFK''s activist roots, the program has become a trusted space for truth-telling, movement-building, and connecting national issues to local communities. Its legacy continues as a catalyst for civic engagement and an ongoing chronicle of people-powered change. Hosts Ralph Nader Ralph Nader is a lifelong advocate for justice whose work has saved lives and transformed laws. From the factory floor to the halls of Congress, he''s empowered everyday people to challenge corporate abuse and defend their communities. Ralph brings seventy years of unyielding citizen action and inspiration to every conversation. Steve Skrovan With roots in Los Angeles and a sharp eye honed as an Emmy-winning comedy writer, Steve Skrovan brings clarity, heart, and humor to tough topics. He has a deep connection to the show''s mission—having chronicled Ralph Nader''s life in "An Unreasonable Man" —and relishes making complex issues personal and real. ✉ Contact nader Episodes KPFK Episode Player Support Independent Media KPFK stands for fearless, independent media—powered by listeners, never corporations. Shows like the Ralph Nader Radio Hour lift up community voices, challenge unchecked power, and refuse to play it safe. Your donation fuels this work and keeps the mic open for the truth-tellers and change-makers our world needs. If you believe in public radio that answers to people, not profit, step up and support KPFK today. Together, we make history possible. Contribute

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Reggae Central', 'reggae-central', 'Website http://www.reggaecentral.org/ Facebook http://www.facebook.com/reggaecentralkpfk Instagram https://www.instagram.com/reggaecentralkpfk/

Chuck Foster hosts Reggae Central Sundays from 2-5 PM on KPFK. He features ska, rocksteady, dub, local and international reggae and dancehall with a special emphasis on roots music. Chuck is the author of Roots Rock Reggae: An Oral History of Reggae Music From Ska To Dancehall (Billboard Books, 1999) and The Small Axe Guide To Rockstedy (Muzik Works, 2009, updated 2016). He wrote the Reggae Update column for Beat Magazine for two decades and currently writes the Reading and Reasoning column for Reggae Festival Guide. Chuck started playing reggae on the radio in Southern California in 1982 and began hosting Reggae Central in 1997. Live guests on the show over the years include Dennis Brown, The Mighty Diamonds, Burning Spear, Alton Ellis, Etana, Stranger Cole, Freddie McGregor, Phyllis Dillon, Lucky Dube, Morgan Heritage, The Expanders and many, many more.

Contact email: cfoster907@yahoo.com

Archives of this show can be heard here: https://archive.kpfk.org/index_one.php?shokey=reggaecent

Aired Sunday September 13 2-5 PM on KPFK

Toots Hibbert, lead singer of the classic Reggae group Toots & the Maytals passed on September 11 from complications of Covid-19. His contribution to reggae music was enormous including the first single with the word "Reggae" in the title in 1969 and a ground-breaking tour with The Rolling Stones in the 70''s that helped introduce Reggae to America to Grammy-winning releases and his latest album "Got To Be Tough" which came out just last week. Chuck Foster will be hosting a three hour special dedicated to the music of Toots Hibbert

Listen to the archive here - https://archive.kpfk.org/index_one.php?shokey=reggaecent

Reggae Central Playlists

Current Playlist

Previous Playlists: (select date) Reggae Central Playlist

Embed not found', '{"facebook": "http://www.facebook.com/reggaecentralkpfk", "instagram": "https://www.instagram.com/reggaecentralkpfk/", "archive": "https://archive.kpfk.org/index_one.php?shokey=reggaecent"}'::jsonb, 'cfoster907@yahoo.com', 'http://www.reggaecentral.org/', true),
    (kpfk_station_id, 'Revolucion Arcoiris', 'revolucion-arcoiris', 'Revolución Arcoíris Truth & Fire — Verdad y Fuego Mondays · 11:30 PM – Midnight Hosted by Marylin Cavanaugh ▶ Episodes About the Show Revolución Arcoíris is a Spanish-language program that provides a thoughtful and inclusive space for dialogue, reflection, and analysis on issues related to human rights, social justice, cultural identity, and the experiences of diverse communities. The program seeks to amplify voices that are often underrepresented, while promoting critical thinking, dignity, and civic engagement. The program presents four shows per month. Two are hosted by Marylin Cavanaugh, while the other two are hosted by independent guest hosts. The program is directed, produced, and edited by Cavanaugh. Host Marylin Cavanaugh Program Director, Host & Producer of Revolución Arcoíris. Marylin is a licensed educator with a Ph.D. in Education and a Master''s in Educational Psychology, with professional experience spanning teaching, special education, and school administration. Beyond the classroom, she is an advocate for LGBTQ+ rights, migrant communities, and social justice — bringing those perspectives to the airwaves every week on KPFK. ✉ Contact ladiverylainclu Episodes KPFK Episode Player Keep This Show On the Air Revolución Arcoíris is powered by listeners like you. Your support keeps independent, Spanish-language LGBTQ+ programming alive on community radio — a space that exists nowhere else on the dial. Contribute', '{"facebook": "https://www.facebook.com/defendiendosergay", "instagram": "https://www.instagram.com/transgendermary/", "youtube": "https://www.youtube.com/@TransgederMarylinVerdadyfuego"}'::jsonb, NULL, 'https://www.tiktok.com/@truth.and.fire', true),
    (kpfk_station_id, 'Rhapsody in Black', 'rhapsody-in-black', 'Rhapsody in Black A celebration of classic blues, R&B, and group harmony from the 1930s to the ''60s. Saturday • 2 PM – 4 PM • KPFK 90.7 FM Hosted by Jim Dawson ▶ Episodes About the Show Two hours of rockin'' and rollin'' from the soul of America—"Mama don''t allow no AI music ''round here." Along with familiar favorites, Jim introduces listeners to obscurities and oddities: early performances by later stars, humorous and startling items about Black history and culture—like a 1952 song about a Los Angeles freeway coming through and fragmenting an African American neighborhood. The down-to-earth street music of Black artists who created the foundation of what is now a worldwide, multi-billion-dollar entertainment phenomenon. Great Googly Moogly. History & Legacy Rhapsody in Black started in the mid-1980s with Bill Gardner, celebrating classic blues, R&B, and vocal harmony that mainstream radio ignored. Jim Dawson inherited it from Bill, bringing first-hand connections to the artists and the stories behind the music. Bill still drops by occasionally to say hello to his fans and play records. Regular guests include Ray Regalado and Anthony Gonzalez, who bring their own perspectives to the show''s playlists. ‹ N.W.A with Dr. Dre and Eazy-E, joined by host Jim Dawson, writer Dane Webb and MC Ren Jim Dawson with Anthony Gonzalez and Ray Regalado, frequent guests on the show Former host Bill Gardner with saxophonist Joe Houston, Jim Dawson behind them › Host Jim Dawson Jim Dawson grew up in West Virginia in the 1950s listening to R&B and rock ''n'' roll, and never stopped. Since moving to Los Angeles in 1977, he''s interviewed dozens of Black recording artists and their families, written liner notes for at least 100 blues and R&B albums, and authored books including "What Was the First Rock ''n'' Roll Record?" He''s managed and produced artists like saxophonist Big Jay McNeely, blues pianist Willie Egan, and singers Richard Berry and Thurston Harris. ✉ Contact rhapsody Episodes KPFK Episode Player Playlists KPFK Playlist - Tabbed Loading playlist... Keep This Show On the Air Rhapsody in Black plays the music of Black artists who created the foundation of American popular music. Your donation keeps these recordings—and their stories—on the air every Saturday. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Rising Up with Sonali', 'sonali-kolhatkar', 'Rising Up With Sonali Solutions Journalism for Social Justice Tuesdays • 3:00 PM • KPFK 90.7 FM Hosted by Sonali Kolhatkar ▶ Episodes About the Show Rising Up With Sonali is a weekly news and culture program spotlighting grassroots solutions and justice-centered reporting. Instead of sensational headlines, the show uplifts real strategies for building economic, racial, gender, and environmental justice. Funded entirely by listeners, Rising Up is fiercely independent. Its theme music comes from Grammy Award–winning band Quetzal , with editorial partnership from YES! Media , a leader in solutions journalism. Host Sonali Kolhatkar Sonali is the host, creator, and executive producer of Rising Up With Sonali . She previously created and hosted Uprising , which became the longest-running drive-time show on KPFK hosted by a woman. An award-winning journalist recognized by the Los Angeles Press Club, Sonali is also the author of Rising Up: The Power of Narrative in Pursuing Racial Justice (2023) and Talking About Abolition: A Police-Free World is Possible (2025). She serves as Senior Editor at YES! Magazine , Senior Correspondent for the Independent Media Institute''s Economy for All project, and is a longtime Pacifica broadcaster. Acknowledgements: With thanks to Anna Buss (Senior Producer & Technical Director) and James Ingalls (Technical Support). ✉ Contact risingupwithsonali Episodes KPFK Episode Player Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Contribute', '{"twitter": "https://x.com/RUWithSonali", "facebook": "https://www.facebook.com/RUwithSonali/", "instagram": "https://www.instagram.com/RUWithSonali"}'::jsonb, NULL, 'https://www.linkedin.com/in/sonali-kolhatkar', true),
    (kpfk_station_id, 'Roots Music & Beyond', 'roots-music-and-beyond', 'Description

Americana to world music sounds, folk to funk, bluegrass to blues and beyond

On Saturday, December 12 on Roots Music and Beyond, Mary Katherine Aldin''s special guest will be Noel Paul Stookey of Peter, Paul & Mary, who''ll be discussing "Hope Rises," a new singer/songwriter compilation CD he has produced.

HOSTS

Mark, Tom & Art at KPFK

First Saturday of every month: Tom Nixon Second Saturday: Patrick Milligan Third Saturday: Art Podell Fourth Saturday: Mark Humphrey Fifth Saturday (when there is one): Mary Katherine Aldin

First Saturday of the month: Tom Nixon tomenixon10@gmail.com Tom Nixon of The Nixon Tapes takes listeners on a dithyrambic musical romp through all eras and areas making the familiar sound unfamiliar and vice versa.

Second Saturday: Patrick Milligan pcmilligan@me.com Patrick Milligan had his first radio hosting experience in the late ‘80s on another Southern California public radio station where Mark Humphrey was music director. In the early ‘90s, Patrick began his career in the record business producing catalog releases in many genres and a diverse list of artists including Buck Owens, Gene Autrey, Aretha Franklin, John Coltrane, Peter, Paul & Mary and most recently, Joni Mitchell. After having been a guest several times recently on Roots Music & Beyond, he is thrilled to be a host and join his esteemed friends and colleagues as a member of the team.

Third Saturday host: Art Podell art@artpodell.com , a bona fide Greenwich Village folkie, one-half of the legendary duo Art and Paul and an original member of The New Christy Minstrels, and Professor

Fourth Saturday host: Mark Humphrey mxxkor@gmail.com , may play a classic recording made on a show date or offer other timely tie-ins to the vital variety of our musical roots.

Current Playlist

Previous Playlists: (select date)

Share Share on Facebook Share on Messenger Share on Messenger Share on X', '{}'::jsonb, 'mxxkor@gmail.com', NULL, true),
    (kpfk_station_id, 'Scholars Circle', 'scholars-circle', 'We seek to elevate the discourse of contemporary issues and discuss the globe''s challenges with scholars and researchers from all over the world.

The Scholars'' Circle team: Doug Becker, Host Maria Armoudian, Host Melissa Chiprin, Managing Producer Ankine Aghassian, Managing Producer Sudd Dongre, Webmaster

Website: www.scholarscircle.org

Twitter: @ScholarsCircle

Published on: www.the bigq.org

Subscribe to this show''s Podcast [ here ]', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=scholacirclepodast"}'::jsonb, NULL, 'http://www.thebigq.org', true),
    (kpfk_station_id, 'Senderos de Oaxaca', 'senderos-de-oaxaca', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'The Signal', 'the-signal', 'The Signal News, Information & Analysis with Dino — from Los Angeles to the world. Weekly • Coming Soon • KPFK 90.7 FM Host: Armando "Dino" Gudiño ▶ Episodes About the Show The Signal is a weekly public affairs program that cuts through the noise to examine the forces shaping Los Angeles, the nation, and the world. The show links local struggles to global currents, bringing advocates, policymakers, academics, artists, and community leaders into focused conversations that matter. With a core focus on labor rights, immigration, democracy, and culture, The Signal gives listeners the context and clarity they need to navigate daily life — a platform for grassroots voices and a forum for serious dialogue about solutions, justice, and the future of our communities. Host Armando "Dino" Gudiño Journalist, policy advocate, and nonprofit leader with 30+ years in public policy, legislation, and community organizing. Dino has worked across 30+ countries on issues from human rights to international relations. On The Signal , he brings a global lens, sharp reporting, and a deep commitment to justice. ✉ Contact signal Episodes KPFK Episode Player Support The Signal & Independent Media Help keep programs like The Signal — and community-powered radio at KPFK — strong. Your contribution makes a difference. Contribute', '{"instagram": "https://www.instagram.com/dinofromla"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Sojourner Truth', 'sojourner-truth', 'Sojourner Truth Radio Uncompromising voices. Ground-level truth. Fridays • 5:00 PM • KPFK 90.7 FM Hosted by Margaret Prescod and Nana Gyamfi ▶ Episodes About the Show Sojourner Truth Radio brings you unapologetic public affairs from the frontlines of global and local struggle. Hosted by journalist and activist Margaret Prescod and human rights attorney Nana Gyamfi, the show amplifies voices too often erased—connecting grassroots organizing to policy, history, and global movements. Each episode offers sharp headlines, deep analysis, and cultural context through a lens of racial justice, gender liberation, and international solidarity. History & Legacy Since its founding in the early 2000s, Sojourner Truth Radio has become a vital platform for connecting grassroots movements with national and international issues. Created and hosted by Margaret Prescod, the show was born out of the urgency to center voices often excluded from mainstream media — from Black women leaders to frontline immigrant organizers. Over two decades, it has covered pivotal moments: the aftermath of Hurricane Katrina, the global women''s strikes, Ferguson uprisings, Standing Rock, and countless international human rights struggles. Its legacy is one of unwavering truth-telling, radical solidarity, and bridging local and global resistance. Hosts Margaret Prescod Journalist, organizer, and international activist, Margaret is the founder of the Black Coalition Fighting Back Serial Murders. She brings fearless, intersectional analysis to every broadcast, amplifying frontline voices worldwide. Nana Gyamfi Human rights attorney, professor, and Executive Director of Black Alliance for Just Immigration. Nana brings sharp legal insight and unwavering commitment to community power and global justice. ✉ Contact sojourner Episodes KPFK Episode Player Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Something''s Happening A Hour 1 honoring Roy Of Hollywood', 'somethings-happening-a-hour-1-honoring-roy-of-hollywood', 'Somethings Happening is KPFK''s long-running overnight program midnight to 6:00 AM Tuesday-Friday with segments of holistic health, meditation, psychology, philosophy, political economy, science fiction and fact, old radio and more, created and long curated by the late Roy of Hollywood, Roy Tuckman. KPFK has been maintaining it since he passed in his honor and memory and in the framework and format he developed and evolved over the decades, which continues to evolve.

Monday overnight to Tuesday features political economy , including Le Show, with Harry Shearer now on at midnight with real-life absurdities from the headlines. Equal Rights and Justice from WBAI also airs at 3:00 AM in that early morning.

Tuesday overnight to Wednesday is holistic health , with Street Sankofa with Dr. Ife Jie, dealing with mental liberation as HipHop artivist and scholar, Herbal Highway from sister station KPFA, Food Sleuth Radio from the Pacifica affiliates unit, and Whole Mother about pregnancy, childbirth and child-rearing from sister station KPFT.

Wednesday overnight to Thursday features an anti-fascist focus, with programming from David Emory''s "For the Record," the Grayzone Radio from Max Blumenthal and Aaron Mate'', also developed for radio on KPFK''s initiative, Final Straw Radio from young anti-authoritarians from the Pacifica affiliates unit, and Out-FM from sister station WBAI in New York.

Thursday overnight to Friday focuses on philosophy, psychology and consciousness/enlightenment , with Alan Watts , The Magical Mystery Tour with Tonio Epstein from the Pacifica affiliates unit, an old radio break with drama, mystery, science fiction and comedy, and at 3:00 AM, Caroline Casey, the Visionary Activist from sister station KPFA in Berkeley, a long-running feature on Something''s Happening. We have also been running occasional lectures from the "History of Philosophy Without Any Gaps" from Kings College in London.

Each hour is separately posted on the station''s archives for easy listening - Somethings Happening A hours 1-3, and Somethings Happening B hours 1-3 each overnight. Check it out! Dynamite radio for night people also available 24-7 on kpfk.org (for listening, not download).', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Soul Rebel Radio', 'soul-rebel-radio', 'Online archives of this show - http://archive.kpfk.org/index.php?shokey=soulrebel Fridays at 7:00 PM

Since 2006, Soul Rebel Radio has been a part of the KPFK family creating segments that include content about: current events, cutting-edge topics, comedy, youth voices, underground music, and interviews with various industry professionals. Make sure to tune in every Friday to KPFK either on the radio or worldwide at www.kpfk.org . Also, Soul Rebel Radio engages with their audience via social media platforms like Facebook and Instagram

Instagram - https://www.instagram.com/soulrebelradiola/?hl=en

Facebook -

Embed not found', '{"archive": "http://archive.kpfk.org/index.php?shokey=soulrebel", "instagram": "https://www.instagram.com/soulrebelradiola/?hl=en"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Soundwaves Radio', 'soundwaves', 'Soundwaves Radio is a weekly open-format radio program that features established and burgeoning artists, creative personalities, and DJ''s from all over the globe.

Expect to hear an assortment of eclectic sounds each and every week from special guests and your hosts, Seano and Val The Vandle.

Soundwaves Radio airs Friday evenings from 8-10 PM.

Archive / Instagram / Soundcloud

For song submissions, media inquiries, potential features, or interviews: soundwavesradio@gmail.com

Seano: Emerging from Los Angeles, CA, Seano has steadily climbed the ranks of working DJs since 2006 and has proven to be a professionally respected fixture of this city’s mercurial nightlife. He’s ramped up crowds for such performers as Stevie Wonder, George Clinton, Ellen DeGeneres, Judd Apatow, and Ali Wong. His residencies include Friday’s at The Shortstop in Echo Park, Saturday’s at Perch in DTLA, and Tuesday’s inside Largo at The Coronet. For the past ten years, Seano, has served as the executive producer and host of Soundwaves Radio which airs weekly on 90.7fm KPFK, Los Angeles. He can also be heard once a month on The Treehouse, a monthly radio program presented by Dublab.

Val The Vandle: Los Angeles, Born-and-Bred DJ Val the Vandle has rocked crowds since 2008. Having helped start an LA-centric music community with a monthly showcase The Spliff, Val was able to spread his love of local artists through this platform. With a pool of talent at his fingertips, he joined a team to start an internet-based web series called LAStereo.TV. He gained notoriety for his energized DJ sets and was selected by clients such as Los Angeles Mayor Eric Garcetti, Nike, Def Jam Records, Red Bull, Sony Pictures, & Guerilla Union. He has toured with the likes of Snoop Dogg, Talib Kweli, Drake, & Wiz Khalifa. DJ Val the Vandle has coined himself, The Tastemaker of LA, since earning the stripes of a trendsetter in the LA music scene.

Current Playlist

Previous Playlists: (select date)', '{"archive": "http://soundwavesradio.com/", "instagram": "https://www.instagram.com/soundwaveskpfk/"}'::jsonb, 'soundwavesradio@gmail.com', 'https://soundcloud.com/swradiola', true),
    (kpfk_station_id, 'Special Programming', 'special-programming', 'KPFK Special Programming News specials, live forums, archival broadcasts & more. Varies • KPFK 90.7 FM ▶ Episodes About the Show KPFK Special Programming spotlights one-off broadcasts: urgent news coverage, live community forums, on-the-ground reporting, and archival deep dives you won''t hear on commercial radio. This page is the permanent hub — check back for new recordings and live announcements. Support KPFK Special Programming KPFK is listener-sponsored — no corporate money, no advertiser vetoes. Specials like these exist because our community funds them directly. Become a Sustaining Member — even $5/month keeps independent voices on the air. Join as a monthly sustainer . Make a One-Time Gift — fuel uninterrupted coverage when it matters most. Give now . Other Ways to Give — vehicles, real estate, stocks, or legacy gifts. Explore options . Volunteer & Get Involved — help produce and promote future specials. Raise your hand . Stay Connected — get alerts for upcoming specials. Subscribe to Dispatch . special Recent Specials KPFK Episode Player Support Independent Media Help keep independent media and KPFK on the air. Your contribution makes a difference. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Stairway To Heaven', 'stairway-to-heaven', 'With Teddy Robinson. A soulful excursion through music and the stories they tell. Teddy Angelo Robinson rewinds your listening mind with classic soul from the artists/creators of the Philly Sound, Motown, Stax / Volt record labels and more. The music spans the late 1950s rhythm & blues to classic 1970s Soul, weaving real life stories in love, relationships, and good ole down home grooving.

Contact : groovyfunkysoul@gmail.com

Podcasts : stairwaytoheaven.podomatic.com

Embed not found

Current Playlist

You need an iframes capable browser to view this content.

Previous Playlists: (select date)

Embed not found', '{}'::jsonb, 'groovyfunkysoul@gmail.com', 'https://stairwaytoheaven.podomatic.com/', true),
    (kpfk_station_id, 'Suplemento Comunitario', 'suplemento-comunitario', 'Suplemento Comunitario: Programa semanal de asuntos públicos en español / Weekly Spanish-Language Public Affairs Show

Martes de 10:30 a 11:30 de la noche / Tuesdays 10:30pm - 11:30pm

Hosts / Anfitriones: Polina Vasiliev, Oscar Ulloa

El programa de las organizaciones sociales en la lucha. Información y análisis relevante a las comunidades migrantes.

Blog : www.suplementocomunitariokpfk.wordpress.com

Facebook: Alerta.LosAngeles

Email: suplementocomunitariokpfk@gmail.com', '{}'::jsonb, 'suplementocomunitariokpfk@gmail.com', 'http://www.suplementocomunitariokpfk.wordpress.com', true),
    (kpfk_station_id, 'Radio Intifada (SWANA Region Radio)', 'swana-region-radio', 'Radio Intifada, the SWANA (South West Asia and North Africa) region radio program, is committed to bringing our listeners a weekly review of politics and culture from Kolkata to Casablanca.

Archives and podcast can be found here - https://archive.kpfk.org/index_one.php?shokey=rintifada

Embed not found', '{"archive": "https://archive.kpfk.org/index_one.php?shokey=rintifada"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Think Outside The Cage', 'think-outside-the-cage', 'Host/Producers/Personnel: Geri Silva, founder, Jesse Bliss, Professor Bidhan Roy & Mark Cofield.

Email: gerifcp@gmail.com

Geri Silva

Think Outside the Cage is a show about the Prison Industrial Complex and the twisted roads that lead to it.  The U.S. spends $181 Billion Dollars annually on the crime control industry, or more accurately the punishment industry , with California alone spending $16 Billion.

Our show comes to you from both sides of the prison walls exploring an industry whose chief product is human degradation, and whose purpose is both profit and social control.

We will explore how and why people end up in prison and what happens to them once they are there.

These rarely addressed questions need answers: What role do police agencies play in the drive to incarcerate?  How do the courts & prosecutors ensure that “justice” equals the loss of freedom?  And what of the undeniable racial imbalance in this criminally unjust system?

Most importantly, we will focus on the resistance, the movement building, the engines of change inside and out.

Jesse Bliss – Is the founder/director of Roots and Wings Project, which provides stage and space for voices of the unnamed, unknown and misunderstood with an intimate exploration of the intricacies of the human spirit in relation to all aspects of incarceration, the intersection of outside and inside the walls, plus the paralleled healing power of the arts as an intervention to the perils of the Prison Industrial Complex...

Honoring the late co-host Jitu Sadiki, of BACDO and Black August LA

Jitu Sadiki ~ Is a member of Black August Los Angeles.  He was a leader in the Black liberation movement while imprisoned in the 70’s and 80’s.  His segments  delved into issues that challenge the inequities of the Prison Industrial Complex, put forth ways to support decarceration, highlight today’s political prisoners and advocated for the greatest number of prisoners who are being impacted by cruel, archaic and repressive laws and penal policies.

Each show will bring on an activist in the movement to decarcerate and a prisoner(s) who is organizing for freedom across the board!', '{}'::jsonb, 'gerifcp@gmail.com', NULL, true),
    (kpfk_station_id, 'This Way Out', 'this-way-out', 'This Way Out The International LGBTQ Radio Magazine Mondays • 7:30–8:00 PM • KPFK 90.7 FM Host: Brian DeShazor | Coordinating Producer: Greg Gordon | Associate Producer: Lucia Chappelle ▶ Episodes About the Show This Way Out is the award-winning LGBTQ radio magazine that''s been on the air since 1988. Each half-hour episode combines a global news wrap-up with features, interviews, and culture pieces, produced by a volunteer team amplifying queer voices worldwide. Heard on more than 200 community stations, streaming online, and available as a podcast, the program is sustained by listener donations. Its mission is simple: tell our own stories in our own voices — connecting the LGBTQ community across borders, generations, and movements. History & Legacy Founded in 1988 after the National March on Washington for Lesbian and Gay Rights, This Way Out was created by veteran radio journalists Greg Gordon and Lucia Chappelle. It quickly became the world''s first internationally syndicated LGBTQ radio magazine. Over 1,700 episodes later, it continues to chronicle queer history in real time — from the AIDS crisis to marriage equality to today''s global human rights battles. The show has earned multiple awards, including honors from the National Federation of Community Broadcasters, GLAAD, and the Golden Mike Awards, and its full archive is being preserved in the Library of Congress. More than a radio program, This Way Out has been a lifeline for listeners worldwide — often the only queer voice available on the dial. Hosts & Team Brian DeShazor Host of This Way Out, Brian also serves as CEO of Overnight Productions, the nonprofit behind the program. A longtime advocate for community media and former director of the Pacifica Radio Archives, he leads the team ensuring queer stories are heard and preserved worldwide. Greg Gordon This Way Out co-founder, coordinating producer, and NewsWrap writer. Greg is a pioneer in LGBTQ broadcast radio, with roots tracing back to the first broadcasts of IMRU on KPFK in 1974. He volunteered with the gay media collective and IMRU until 1984. He covered the Marches on Washington for Gay and Lesbian Rights, along with Lucia Chappelle, live for Pacifica Radio in 1979 and 1987, and he famously interviewed Harvey Milk in 1979, shortly before Milk''s assassination. He holds a bachelor''s degree in Radio–Television Production from UCLA. Lucia Chappelle Associate Producer and co-founder, Lucia has helped shape This Way Out''s voice since 1988. A former KPFK public affairs director and lifelong activist, she continues to guide the show''s editorial direction and mentor new generations of queer media makers. ✉ Contact thiswayout Episodes KPFK Episode Player Support This Way Out & Independent Media Help keep programs like This Way Out — and community-powered radio at KPFK — strong. Your contribution makes a difference. Contribute', '{"instagram": "https://www.instagram.com/thiswayoutradio", "facebook": "https://www.facebook.com/ThisWayOutRadio"}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Thom Hartmann', 'thom-hartmann', 'Host/Producers/Personnel: Thom Hartmann Program Time and Day M - F 9 AM to 10 AM

TAKING YOUR CALLS LIVE DURING THE SHOW AT (202) 808-9925

Website Link(s): http://www. thomhartmann .com

Social Media Link(s):  FOLLOW THOM ► AMAZON : http://amzn.to/2hS4UwY ► BLOG : http://www.thomhartmann.com/thom/blog ► FACEBOOK : Embed not found ► INSTAGRAM : http://www.instagram.com/Thom_Hartmann ► PATREON : http://www.patreon.com/thomhartmann ► TWITTER : http://www.twitter.com/thom_hartmann ► WEBSITE : http://www.thomhartmann.com ► YOUTUBE : https://www.youtube.com/user/thomhartmann

Description: Thom Hartmann is the four-time Project Censored Award-winning, New York Times best-selling author of 25 books currently in print in over a dozen languages on five continents in the fields of psychiatry, ecology, politics, and economics, and the #1 progressive talk show host in the United States. He has helped set up hospitals, famine relief programs, schools, and refugee centers in India, Uganda, Australia, Colombia, Russia, and the United States. Formerly rostered with the State of Vermont as a psychotherapist, founder of The Michigan Healing Arts Center, and licensed as an NLP Trainer by Richard Bandler, he was the originator of the revolutionary "Hunter/Farmer Hypothesis" to understand Attention Deficit Hyperactive Disorder (ADHD). In the field of environmentalism, Thom has co-written and starred in 4 documentaries with Leonardo DiCaprio, and is also featured in his documentary theatrical release The 11th Hour. His book The Last Hours of Ancient Sunlight, about the end of the age of oil, is an international bestseller and used as a textbook in many schools.

ARCHIVES', '{"youtube": "https://www.youtube.com/user/thomhartmann", "instagram": "http://www.instagram.com/Thom_Hartmann", "twitter": "http://www.twitter.com/thom_hartmann"}'::jsonb, NULL, 'http://www.thomhartmann.com', true),
    (kpfk_station_id, 'Travel Tips for Aztlan', 'travel-tips-for-aztlan', 'Current Playlist

You need an iframes capable browser to view this content.

Previous Playlists: (select date)', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Voces de Libertad', 'voces-de-libertad', NULL, '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Way Out West', 'way-out-west', 'Way Out West Jazz, Blues, and Beyond — West Coast Sounds Saturday • 5:00–7:00 AM • KPFK 90.7 FM Hosted by Jerry Ough ▶ Episodes About the Show Way Out West is your early morning journey into the heart and future of jazz, blues, classic R&B, and the West Coast''s most daring new sounds. Every Saturday from 5 to 7am, we cut through the noise to bring you artists who push boundaries and honor roots—voices and legends who shape, challenge, and celebrate the music made by real communities right here and across the globe. You''ll hear genre-bending tracks, deep-catalog favorites, and stories often missed by the mainstream. If you care about the people, places, and passions behind the music, Way Out West is where you''ll find their heartbeat—on your dial and in your community. History & Legacy Way Out West draws on Jerry Ough''s decades-long legacy as a driving force in west coast jazz radio, building on a foundation laid at celebrated stations like KJAZ in Alameda and KLON in Long Beach. With roots reaching back more than forty years in California''s music scene, the program continues a tradition of deep reporting and artist-centered storytelling that has shaped public radio''s coverage of jazz and blues in Los Angeles and beyond. Way Out West reflects Ough''s commitment to spotlighting overlooked artists and unsung chapters in music history, connecting generations of listeners to the evolving rhythms of their communities. The show stands as a living archive and amplifier for the voices that have defined, and continue to redefine, the landscape of American music on the West Coast. Host Jerry Ough Jerry Ough is the longest-running jazz radio journalist in Los Angeles, with over forty years behind the mic amplifying real artists and their stories. From his early days at KJAZ in the Bay Area to key reporting roles at KLON, KPFK, and beyond, Jerry brings deep roots and hard-won knowledge of California''s musical landscape. His approach is always people-first—connecting listeners to the communities, histories, and fresh sounds that keep jazz, blues, and boundary-pushing music alive. ✉ Contact wayoutwest Episodes KPFK Episode Player Playlists KPFK Playlist - Tabbed Loading playlist... Support Independent Media Keep community-powered radio alive. KPFK brings you sounds and stories you won''t hear anywhere else—amplifying real artists, real histories, and real change. Support independent media driven by people, not corporations. Every dollar keeps our music and movement strong. Join us and make a difference—your contribution matters. Contribute', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'Working Voices', 'working-voices', 'Hosts : Joe Ayala & Enrique Sanchez Producer : Dan McCrory

Airs Mondays 5-6am

Wake up early with Working Voices!

Working Voices is a labor of love for us because of our love for labor. The labor movement has pulled many folks out of poverty and taught us leadership skills and the ability to help even more.   We''re here to teach, to learn, to share our expertise and our experiences.

I’m Joe Ayala , president of NABET/CWA Local 9503 in Burbank. I served as VP for 14 years before being elected president of the Burbank local. Most of Local 53’s members work in the predominately Latino media and sharing information has become such an important part of journalism.

My name is Enrique Sanchez , founder and director of Spanish United established in 2020. I am a leader in the community in which I live as well as a leader in the Hispanic community. My background is in education specifically in Political Science as it pertains to education. I work as a freelance educator and a podcaster covering issues within the Hispanic community, lobbying to bring social justice to the Latinx community through education, reforms, and investment.

I’m Dan McCrory , former president of CWA Local 9503. I served as Secretary for the National Writers Union for 17 years before being elected Chair of the union’s book division. Served on CWA Local 9503 executive board 9 years. Rooted out corruption in both unions. President, AT&T Pioneers philanthropic organization.', '{}'::jsonb, NULL, NULL, true),
    (kpfk_station_id, 'World Massive with D. Painter', 'dj-potira', 'Massive sounds from across the globe including moombahton, baile funk, dancehall, afrobeats, bhangra and much more. Guest DJs / producers, both local and international, join host d.painter weekly to expose you to the latest in modern world music.

LA based by way of Washington DC, d.painter has a long history with Pacifica radio going back to WPFW in the Nation''s capital. Since moving to the West Coast, d.painter has become known for mixing eclectic sounds from open format sets at residencies across L.A. to the global sounds of his Moombah Sessions, World 70 and Sucia Bonita parties he produces with his partners at FADE L.A. Follow him on IG @djdpainter and find his original music on all streaming platforms.

www.DJDPainter.com

MUSIC:

mixes  mixcloud.com/dpainter original music  soundcloud.com/d-painter

SOCIAL MEDIA:

Instagram @djdpainter

Twitter @dj_dpainter

Tweets by DJ_DPainter

Current Playlist You need an iframes capable browser to view this content.

Previous Playlists: (select date) Previous Playlists', '{"twitter": "https://twitter.com/DJ_DPainter?ref_src=twsrc%5Etfw"}'::jsonb, NULL, 'http://soundcloud.com/d-painter', true)
  ON CONFLICT (station_id, slug) WHERE deleted_at IS NULL DO UPDATE SET
    description = EXCLUDED.description,
    social_links = EXCLUDED.social_links,
    contact_email = EXCLUDED.contact_email,
    website_url = EXCLUDED.website_url;

END $$;
