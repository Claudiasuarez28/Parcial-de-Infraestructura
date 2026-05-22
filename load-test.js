import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 20,
  duration: '30s',
};

export default function () {
  let res = http.get('http://app-load-balancer-2101982842.us-east-1.elb.amazonaws.com/health');

  check(res, {
    'status es 200': (r) => r.status === 200,
  });

  sleep(1);
}
