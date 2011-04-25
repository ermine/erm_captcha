#include <gd.h>
#include "gdfontl.h"
#include "gdfontg.h"
#include <string.h>

int main(int argc, char **argv) {
  gdImagePtr im;
  int black;
  int white;
  char *s;
  if (argc > 1) {
    s = argv[1];
  } else {
    return 1;
  };

  im = gdImageCreate(100, 50);
  white = gdImageColorAllocate(im, 255, 255, 255);
  black = gdImageColorAllocate(im, 0, 0, 0);
  gdImageString(im, gdFontGiant,
		im->sx / 2 - (strlen(s) * gdFontGetGiant()->w / 2),
		im->sy / 2 - gdFontGetGiant()->h / 2,
		s, black);
  gdImagePng(im, stdout);
  gdImageDestroy(im);
  return 0;
}
