BEGIN {
    RS = "---\n";
    FS = "\n";
    ignoreDir = "";  
}

{
    if ($0 ~ /# Source: /) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^# Source: /) {
                originalPath = substr($i, 11);
                split(originalPath, pathParts, "/");
                numParts = length(pathParts);
                
                path = "";
                for (idx = 3; idx <= numParts; idx++) {
                    if (path == "") {
                        path = pathParts[idx];
                    } else {
                        path = path "/" pathParts[idx];
                    }
                }

                if (path == "") {
                    print "Warning: Path is empty after removing levels: " originalPath | "cat >&2";
                    next;
                }

                filePath = "./base/" path;
                dirPath = getDirPath(filePath);

                cmd = "mkdir -p \"" dirPath "\"";
                if (system(cmd) != 0) {
                    print "Error creating directory structure: " dirPath | "cat >&2";
                    next;
                }

                if (system("test -d \"" dirPath "\"") != 0) {
                    print "Directory was not created: " dirPath | "cat >&2";
                    next;
                }

                lastDot = match(filePath, /\.[^.]+$/);  # Trouve la dernière extension
                if (lastDot) {
                    baseName = substr(filePath, 1, lastDot - 1);
                    ext = substr(filePath, lastDot);
                } else {
                    baseName = filePath;
                    ext = "";
                }

                if (baseName == "" && ext == "") {
                    print "Error: splitFilePath returned empty values for " filePath | "cat >&2";
                    next;
                }

                newFilePath = filePath;
                count = 1;
                while (system("[ -f \"" newFilePath "\" ]") == 0) {
                    newFilePath = baseName "_" count ext;
                    count++;
                }
                
                filePath = newFilePath;  # Met à jour filePath avec le nom disponible
                
                print "---" > filePath;
                
                for (j = i + 1; j <= NF; j++) {
                    if ($j !~ /^---$/ && $j !~ /^# Source: /) {
                        print $j >> filePath;
                    }
                }
                
                close(filePath);
                break;
            }
        }
    }
}

function getDirPath(fullPath,   parts, count, dir, i) {
    count = split(fullPath, parts, "/");
    dir = parts[1];
    for (i = 2; i < count; i++) {
        dir = dir "/" parts[i];
    }
    return dir;
}