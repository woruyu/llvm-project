// RUN: llvm-mc -triple=woruyu -show-encoding < %s | FileCheck %s

r1 = i ll
// CHECK: r1 = i ll                               # encoding: [0x18'A',0x01'A',A,A,A,A,A,A,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]