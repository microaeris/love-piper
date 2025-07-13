extern vec3 topColor;
        extern vec3 bottomColor;
        extern float love_time;
        extern vec2 screenSize;

        float hash(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }

        vec3 starColor(vec2 p) {
            float h = hash(p);
            if (h < 0.33) return vec3(1.0, 0.9, 0.7);      // warm yellowish
            else if (h < 0.66) return vec3(0.7, 0.8, 1.0); // cool bluish
            else return vec3(1.0, 1.0, 1.0);               // white
        }

        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
        {
            float t = screen_coords.y / screenSize.y;
            vec3 col = mix(bottomColor, topColor, 1.0 - t);

            float starDensity = 600.0;
            float starThreshold = 0.9965;

         
            vec2 normCoords = screen_coords / screenSize;

      
            float rnd = hash(normCoords * starDensity);

            float starPresence = step(starThreshold, rnd);


            float flicker = 0.5 + 0.5 * sin(screen_coords.x * 20.0 + love_time * 15.0);
            starPresence *= flicker;

            vec3 starCol = starColor(normCoords * starDensity);

            col += starPresence * starCol;

            col = min(col, vec3(1.0));

            return vec4(col, 0.5);
        }