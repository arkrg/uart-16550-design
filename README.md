
### 레지스터 변경 목록(A)

- [ ] 1 uart_registers tb 환경 구축 ()
- [x] 2 LCR: WLS=`11`, STB=`0`, stick=`0`, Set Break=`0` 상수화. 리셋 0x03.
- [ ] 3 ㄴ동작 확인
- [ ] 4 LSR에 PE, FE를 dut와 연결
- [ ] 5ㄴ동작 확인
- [ ] 6 RBR 읽기: RX FIFO empty이면 0x00 반환 (pointer는 이미 불변).
- [ ] 7ㄴ동작 확인
- [x] 8 SCR 레지스터 + addr 7 디코드 (DLAB 무관).
- [ ] 9ㄴ동작 확인
- [x] 10  TX FIFO full에서 THR 쓰기 무시, RX FIFO full에서 덮어쓰기 없는지 확인

### RTL 변경 목록(B)

- [x] TX: parity 비트 생성 (PEN/EPS).
- [x] ㄴ 변경된 TX TB 확인  
- busy를 한클럭 앞당김
- [x] RX: parity 검사(PE), stop 검사(FE).
- [ ] ㄴ 변경된 RX TB 확인  

### uart datapath 이상(fifo 포함, C)

- [ ] 1 FIFO에 FE/PE함께 push. (엔트리에 플래그 저장-->무슨의미)
- [ ] 2 RX fifo 비트 확장
- [ ] 3 OE는 fifo가 full일때 새로운 rx_done이 들어오면 OE가 뜸 -->
- [ ] 4 RX FIFO 폭 확장: 데이터 8bit + PE + FE (10bit). 데이터와 플래그는 한 번에 함께 push/pop.
- [ ] LSR 생성: PE/FE = 맨 앞 엔트리 플래그 (empty면 0),
- [ ] bit 7 = 전체 엔트리 PE/FE의 OR, OE = LSR 읽기 클리어 (새 에러 우선?, access 사이클 기준). --> ? 무슨의미
- [x] baud 카운터: divisor==0이면 tick 정지 (신규 안전장치).
- [x] baud 카운터: divisor==1이면 bypass (확인필요).
- [ ] PREADY: 상수 1로 변경.
- [ ]  부작용(RBR pop, THR push, LSR의 OE 클리어)이 access 사이클에서 한 번만 일어나는지 확인하고 필요시 수정.
# uart-16550-design
