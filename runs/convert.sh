#!/bin/bash

for file in *; do cwebp -q 10 $file -o ../webp/${file%.*}.webp; done
